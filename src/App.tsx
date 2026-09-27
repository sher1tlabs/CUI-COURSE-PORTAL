import React, { useState, useMemo } from 'react';
import {
  BookOpen,
  Calendar,
  GraduationCap,
  Home,
  User,
  Bell,
  CheckCircle2,
  AlertTriangle,
  Clock,
  MapPin,
  Search,
  Filter,
  ArrowLeft,
  ChevronRight,
  LogOut,
  Settings,
  Edit3,
  Code2,
  ExternalLink,
  Shield,
  Smartphone,
  Info,
  Check,
  X,
  FileCode2,
  Download,
  Copy,
} from 'lucide-react';
import {
  initialStudent,
  mockCourses,
  mockSections,
  initialRegistrations,
  mockInstructors,
  mockNotifications,
  mockSemesterHistory,
  completedCourseCodes,
} from './mockData';
import { Course, Instructor, Section } from './types';
import { db, auth } from './firebase';
import { doc, setDoc, deleteDoc } from 'firebase/firestore';

// Convert time to minutes for conflict checking
function timeToMinutes(timeStr: string): number {
  const parts = timeStr.trim().split(' ');
  if (parts.length < 2) return 0;
  const [hStr, mStr] = parts[0].split(':');
  let h = parseInt(hStr, 10) || 0;
  const m = parseInt(mStr, 10) || 0;
  const meridian = parts[1].toUpperCase();
  if (meridian === 'PM' && h !== 12) h += 12;
  if (meridian === 'AM' && h === 12) h = 0;
  return h * 60 + m;
}

export default function App() {
  // App navigation state
  const [authState, setAuthState] = useState<'welcome' | 'login' | 'forgot' | 'authenticated'>('authenticated');
  const [activeTab, setActiveTab] = useState<'home' | 'courses' | 'timetable' | 'academic' | 'profile'>('home');
  const [isDarkMode, setIsDarkMode] = useState(true);
  const [deviceFrame, setDeviceFrame] = useState(true);

  // Sub-screens & modals
  const [selectedCourseForDetails, setSelectedCourseForDetails] = useState<Course | null>(null);
  const [selectedCourseForSections, setSelectedCourseForSections] = useState<Course | null>(null);
  const [isChangingSectionMode, setIsChangingSectionMode] = useState(false);
  const [showMyCoursesScreen, setShowMyCoursesScreen] = useState(false);
  const [showNotificationsScreen, setShowNotificationsScreen] = useState(false);
  const [showEditProfileModal, setShowEditProfileModal] = useState(false);
  const [showRegistrationSummaryModal, setShowRegistrationSummaryModal] = useState(false);
  const [selectedInstructorModal, setSelectedInstructorModal] = useState<Instructor | null>(null);
  const [selectedSemesterModal, setSelectedSemesterModal] = useState<typeof mockSemesterHistory[0] | null>(null);
  const [showFlutterSourceModal, setShowFlutterSourceModal] = useState(false);

  // Registration rule engine state
  const [student, setStudent] = useState(initialStudent);
  const [isRegistrationOpen, setIsRegistrationOpen] = useState(true);
  const [registrationDeadline] = useState('September 30, 2026 • 11:59 PM');
  const [minCreditHours] = useState(12);
  const [maxCreditHours] = useState(18);

  const [sections, setSections] = useState<Section[]>(mockSections);
  const [registrations, setRegistrations] = useState(initialRegistrations);
  const [notifications, setNotifications] = useState(mockNotifications);

  // Filters & Search
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDept, setSelectedDept] = useState('All');
  const [selectedType, setSelectedType] = useState('All');
  const [selectedCredits, setSelectedCredits] = useState<number | null>(null);
  const [showFilterDrawer, setShowFilterDrawer] = useState(false);

  // Timetable state
  const [selectedTimetableDay, setSelectedTimetableDay] = useState('Monday');
  const [timetableMode, setTimetableMode] = useState<'day' | 'week'>('day');

  // Confirmation dialogs
  const [registerConfirmSection, setRegisterConfirmSection] = useState<{ course: Course; section: Section } | null>(null);
  const [dropConfirmCourse, setDropConfirmCourse] = useState<{ code: string; title: string } | null>(null);
  const [errorDialog, setErrorDialog] = useState<string | null>(null);
  const [successToast, setSuccessToast] = useState<string | null>(null);

  // Toast timer
  const triggerToast = (msg: string) => {
    setSuccessToast(msg);
    setTimeout(() => setSuccessToast(null), 3500);
  };

  // Credit calculation
  const totalRegisteredCredits = useMemo(() => {
    return registrations.reduce((sum, reg) => {
      const c = mockCourses.find((course) => course.code === reg.courseCode);
      return sum + (c ? c.creditHours : 0);
    }, 0);
  }, [registrations]);

  const availableCredits = maxCreditHours - totalRegisteredCredits;

  // Prerequisite check rule
  const checkPrerequisites = (course: Course) => {
    if (!course.prerequisites || course.prerequisites.length === 0) {
      return { passed: true, message: 'No prerequisites' };
    }
    const missing = course.prerequisites.filter((p) => !completedCourseCodes.has(p));
    if (missing.length === 0) {
      return { passed: true, message: 'Prerequisites Completed' };
    }
    return {
      passed: false,
      message: `Required: ${missing.join(', ')}`,
      missing,
    };
  };

  // Schedule conflict check rule
  const checkScheduleConflict = (targetSection: Section, ignoreCourseCode?: string) => {
    const targetStart = timeToMinutes(targetSection.startTime);
    const targetEnd = timeToMinutes(targetSection.endTime);

    for (const reg of registrations) {
      if (ignoreCourseCode && reg.courseCode === ignoreCourseCode) continue;
      const regSection = sections.find((s) => s.id === reg.sectionId);
      if (!regSection) continue;

      // Common days
      const commonDays = regSection.days.filter((d) => targetSection.days.includes(d));
      if (commonDays.length === 0) continue;

      const regStart = timeToMinutes(regSection.startTime);
      const regEnd = timeToMinutes(regSection.endTime);

      if (targetStart < regEnd && targetEnd > regStart) {
        return {
          hasConflict: true,
          conflictCourseCode: reg.courseCode,
          conflictTime: `${regSection.startTime} - ${regSection.endTime}`,
          commonDays: commonDays.join(', '),
          message: `${targetSection.courseCode} overlaps with registered ${reg.courseCode} on ${commonDays.join(', ')} (${regSection.startTime} - ${regSection.endTime}).`,
        };
      }
    }
    return { hasConflict: false };
  };

  // Registration action
  const handleRegisterConfirm = () => {
    if (!registerConfirmSection) return;
    const { course, section } = registerConfirmSection;

    if (!isRegistrationOpen) {
      setErrorDialog('Registration period is currently closed.');
      setRegisterConfirmSection(null);
      return;
    }

    if (registrations.some((r) => r.courseCode === course.code)) {
      setErrorDialog('You are already registered for this course.');
      setRegisterConfirmSection(null);
      return;
    }

    const prereq = checkPrerequisites(course);
    if (!prereq.passed) {
      setErrorDialog(`Prerequisites not completed: ${prereq.message}`);
      setRegisterConfirmSection(null);
      return;
    }

    if (totalRegisteredCredits + course.creditHours > maxCreditHours) {
      setErrorDialog(`Credit hour limit exceeded! Maximum allowed is ${maxCreditHours} CH.`);
      setRegisterConfirmSection(null);
      return;
    }

    if (section.availableSeats <= 0) {
      setErrorDialog(`Section ${section.sectionName} is full.`);
      setRegisterConfirmSection(null);
      return;
    }

    const conflict = checkScheduleConflict(section);
    if (conflict.hasConflict) {
      setErrorDialog(conflict.message || 'Schedule conflict detected.');
      setRegisterConfirmSection(null);
      return;
    }

    // Success: Register
    const regId = `reg_${Date.now()}`;
    const newReg = {
      id: regId,
      studentId: student.id,
      courseCode: course.code,
      sectionId: section.id,
      semester: 'Spring 2026',
      status: 'Registered' as const,
      registrationDate: new Date().toISOString().split('T')[0],
    };

    setRegistrations((prev) => [...prev, newReg]);

    setSections((prev) =>
      prev.map((s) => (s.id === section.id ? { ...s, availableSeats: s.availableSeats - 1 } : s))
    );

    // Persist registration to Firebase Firestore
    try {
      setDoc(doc(db, 'registrations', regId), {
        studentId: student.id,
        courseCode: course.code,
        courseTitle: course.title,
        creditHours: course.creditHours,
        sectionId: section.id,
        sectionCode: section.sectionName,
        instructorName: section.instructor,
        days: section.days,
        timeSlot: `${section.startTime} - ${section.endTime}`,
        room: section.room,
        semester: 'Spring 2026',
        status: 'Registered',
        registeredAt: new Date().toISOString(),
      }).catch((err) => console.warn('Firestore write warning:', err));
    } catch (e) {
      console.warn('Firestore write error:', e);
    }

    setRegisterConfirmSection(null);
    setSelectedCourseForSections(null);
    triggerToast(`Registered for ${course.code} (${section.sectionName}) successfully! Saved to Firestore.`);
  };

  // Change section action
  const handleChangeSection = (course: Course, newSection: Section) => {
    const regIndex = registrations.findIndex((r) => r.courseCode === course.code);
    if (regIndex === -1) {
      setErrorDialog('Course is not registered.');
      return;
    }
    const currentReg = registrations[regIndex];
    if (currentReg.sectionId === newSection.id) {
      setErrorDialog('You are already enrolled in this section.');
      return;
    }
    if (newSection.availableSeats <= 0) {
      setErrorDialog('This section is full.');
      return;
    }
    const conflict = checkScheduleConflict(newSection, course.code);
    if (conflict.hasConflict) {
      setErrorDialog(conflict.message || 'Schedule conflict detected with new section.');
      return;
    }

    // Free seat in old section, decrement in new
    setSections((prev) =>
      prev.map((s) => {
        if (s.id === currentReg.sectionId) return { ...s, availableSeats: s.availableSeats + 1 };
        if (s.id === newSection.id) return { ...s, availableSeats: s.availableSeats - 1 };
        return s;
      })
    );

    setRegistrations((prev) => {
      const copy = [...prev];
      copy[regIndex] = { ...copy[regIndex], sectionId: newSection.id };
      return copy;
    });

    setSelectedCourseForSections(null);
    setIsChangingSectionMode(false);
    triggerToast(`Switched ${course.code} to ${newSection.sectionName}.`);
  };

  // Drop course action
  const handleDropConfirm = () => {
    if (!dropConfirmCourse) return;
    const reg = registrations.find((r) => r.courseCode === dropConfirmCourse.code);
    if (reg) {
      setSections((prev) =>
        prev.map((s) => (s.id === reg.sectionId ? { ...s, availableSeats: s.availableSeats + 1 } : s))
      );
      setRegistrations((prev) => prev.filter((r) => r.courseCode !== dropConfirmCourse.code));
      triggerToast(`Dropped ${dropConfirmCourse.code} successfully. Updated in Firestore.`);

      // Delete from Firebase Firestore
      try {
        deleteDoc(doc(db, 'registrations', reg.id)).catch((err) => console.warn('Firestore delete warning:', err));
      } catch (e) {
        console.warn('Firestore delete error:', e);
      }
    }
    setDropConfirmCourse(null);
  };

  // Filtered courses
  const filteredCourses = useMemo(() => {
    return mockCourses.filter((course) => {
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchCode = course.code.toLowerCase().includes(q);
        const matchTitle = course.title.toLowerCase().includes(q);
        const matchDept = course.department.toLowerCase().includes(q);
        if (!matchCode && !matchTitle && !matchDept) return false;
      }
      if (selectedDept !== 'All' && course.department !== selectedDept) return false;
      if (selectedType !== 'All' && course.courseType !== selectedType) return false;
      if (selectedCredits !== null && course.creditHours !== selectedCredits) return false;
      return true;
    });
  }, [searchQuery, selectedDept, selectedType, selectedCredits]);

  // Timetable entries for day
  const getTimetableForDay = (day: string) => {
    const list: Array<{
      course: Course;
      section: Section;
      startTime: string;
      endTime: string;
      room: string;
      instructor: string;
    }> = [];

    registrations.forEach((reg) => {
      const course = mockCourses.find((c) => c.code === reg.courseCode);
      const section = sections.find((s) => s.id === reg.sectionId);
      if (course && section && section.days.includes(day)) {
        list.push({
          course,
          section,
          startTime: section.startTime,
          endTime: section.endTime,
          room: section.room,
          instructor: section.instructor,
        });
      }
    });

    return list.sort((a, b) => timeToMinutes(a.startTime) - timeToMinutes(b.startTime));
  };

  // Unread notifications count
  const unreadNotifCount = notifications.filter((n) => !n.isRead).length;

  return (
    <div className={`min-h-screen ${isDarkMode ? 'bg-[#0a0a0a] text-neutral-100' : 'bg-neutral-100 text-neutral-900'} flex flex-col font-sans transition-colors duration-200`}>
      {/* Top Banner & Control Bar */}
      <header className={`border-b ${isDarkMode ? 'bg-[#111111] border-neutral-800' : 'bg-white border-neutral-200'} px-4 py-2.5 flex items-center justify-between text-xs sticky top-0 z-50`}>
        <div className="flex items-center gap-2">
          <div className={`w-6 h-6 rounded-md flex items-center justify-center font-black text-xs ${isDarkMode ? 'bg-white text-black' : 'bg-black text-white'}`}>
            CUI
          </div>
          <div>
            <span className="font-bold tracking-tight text-sm">COMSATS Student Portal</span>
            <span className="hidden sm:inline-block ml-2 px-1.5 py-0.5 rounded bg-neutral-500/20 text-[10px] font-mono">
              Flutter / Dart Material 3
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowFlutterSourceModal(true)}
            className={`flex items-center gap-1.5 px-2.5 py-1 rounded-md border font-medium transition ${
              isDarkMode
                ? 'border-neutral-700 bg-neutral-800 hover:bg-neutral-700 text-neutral-200'
                : 'border-neutral-300 bg-neutral-100 hover:bg-neutral-200 text-neutral-800'
            }`}
            title="Inspect Flutter / Dart project files and APK build instructions"
          >
            <Code2 size={13} />
            <span className="hidden sm:inline">Flutter Source Code & APK</span>
            <span className="sm:hidden">Dart</span>
          </button>

          <button
            onClick={() => setDeviceFrame(!deviceFrame)}
            className={`hidden md:flex items-center gap-1 px-2 py-1 rounded-md border font-medium ${
              isDarkMode ? 'border-neutral-700 hover:bg-neutral-800' : 'border-neutral-300 hover:bg-neutral-200'
            }`}
          >
            <Smartphone size={13} />
            <span>{deviceFrame ? 'Frame: ON' : 'Full Width'}</span>
          </button>

          <button
            onClick={() => setIsDarkMode(!isDarkMode)}
            className={`p-1.5 rounded-md border ${
              isDarkMode ? 'border-neutral-700 hover:bg-neutral-800' : 'border-neutral-300 hover:bg-neutral-200'
            }`}
            title="Toggle Monochrome Dark / Light"
          >
            {isDarkMode ? '☀️ Light' : '🌙 Dark'}
          </button>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 flex items-center justify-center p-0 md:p-6 overflow-x-hidden">
        <div
          className={`w-full ${
            deviceFrame
              ? 'max-w-[420px] md:rounded-[36px] md:border md:shadow-2xl overflow-hidden'
              : 'max-w-2xl md:rounded-2xl md:border'
          } ${
            isDarkMode
              ? 'bg-[#0f0f0f] border-neutral-800 shadow-black/80'
              : 'bg-white border-neutral-200 shadow-neutral-300'
          } min-h-[780px] flex flex-col relative`}
        >
          {/* Native Phone Status Bar Simulation (Android Style) */}
          <div className={`px-6 pt-3 pb-1 flex items-center justify-between text-[11px] font-medium tracking-tight ${isDarkMode ? 'text-neutral-400' : 'text-neutral-500'}`}>
            <span>09:41</span>
            <div className="flex items-center gap-1.5">
              <span>5G</span>
              <div className="w-4 h-2 rounded-sm border border-current flex items-center p-0.5">
                <div className="w-2.5 h-full bg-current rounded-2xs" />
              </div>
            </div>
          </div>

          {/* Toast Notification */}
          {successToast && (
            <div className="absolute top-12 left-4 right-4 z-50 bg-neutral-900 text-white border border-neutral-700 px-4 py-3 rounded-xl shadow-lg flex items-center gap-2 text-xs animate-in fade-in slide-in-from-top duration-200">
              <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
              <span className="flex-1 font-medium">{successToast}</span>
              <button onClick={() => setSuccessToast(null)}>
                <X size={14} className="text-neutral-400" />
              </button>
            </div>
          )}

          {/* ========================================================= */}
          {/* AUTH SCREENS */}
          {/* ========================================================= */}
          {authState === 'welcome' && (
            <div className="flex-1 flex flex-col justify-between p-6">
              <div className="my-auto pt-10">
                <div className={`w-16 h-16 rounded-2xl flex items-center justify-center font-extrabold text-2xl tracking-wider mb-8 ${isDarkMode ? 'bg-white text-black' : 'bg-black text-white'}`}>
                  CUI
                </div>
                <h1 className="text-3xl font-extrabold tracking-tight leading-tight mb-3">
                  COMSATS<br />Student Portal
                </h1>
                <p className={`text-sm leading-relaxed ${isDarkMode ? 'text-neutral-400' : 'text-neutral-600'}`}>
                  Your university. Your courses. Your semester.<br />
                  Manage course registration, section selection, timetable, and academic progress in one native app.
                </p>
              </div>

              <div className="space-y-3 pb-6">
                <button
                  onClick={() => setAuthState('login')}
                  className={`w-full py-3.5 rounded-xl font-semibold text-sm transition ${
                    isDarkMode ? 'bg-white text-black hover:bg-neutral-200' : 'bg-black text-white hover:bg-neutral-800'
                  }`}
                >
                  Login with University Email
                </button>
                <button
                  onClick={() => setAuthState('authenticated')}
                  className={`w-full py-3.5 rounded-xl font-semibold text-sm border transition ${
                    isDarkMode
                      ? 'border-neutral-700 text-white hover:bg-neutral-800'
                      : 'border-neutral-300 text-black hover:bg-neutral-100'
                  }`}
                >
                  Continue as Demo Student
                </button>
                <p className="text-[11px] text-center text-neutral-500 pt-2">
                  COMSATS University Islamabad • Official Portal
                </p>
              </div>
            </div>
          )}

          {authState === 'login' && (
            <div className="flex-1 flex flex-col p-6">
              <button
                onClick={() => setAuthState('welcome')}
                className="self-start p-2 -ml-2 text-neutral-400 hover:text-neutral-100 mb-4"
              >
                <ArrowLeft size={18} />
              </button>
              <h2 className="text-2xl font-bold tracking-tight">Student Login</h2>
              <p className={`text-xs mt-1 mb-6 ${isDarkMode ? 'text-neutral-400' : 'text-neutral-600'}`}>
                Sign in with your official university credentials
              </p>

              <div className="space-y-4 flex-1">
                <div>
                  <label className="block text-xs font-semibold mb-1.5">University Email</label>
                  <input
                    type="email"
                    defaultValue="sp24-bce-042@isb.comsats.edu.pk"
                    className={`w-full px-3.5 py-3 rounded-xl text-sm border ${
                      isDarkMode
                        ? 'bg-neutral-900 border-neutral-800 focus:border-white'
                        : 'bg-neutral-50 border-neutral-300 focus:border-black'
                    } outline-none transition`}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1.5">Registration Number</label>
                  <input
                    type="text"
                    defaultValue="SP24-BCE-042"
                    className={`w-full px-3.5 py-3 rounded-xl text-sm border ${
                      isDarkMode
                        ? 'bg-neutral-900 border-neutral-800 focus:border-white'
                        : 'bg-neutral-50 border-neutral-300 focus:border-black'
                    } outline-none transition`}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold mb-1.5">Password</label>
                  <input
                    type="password"
                    defaultValue="password123"
                    className={`w-full px-3.5 py-3 rounded-xl text-sm border ${
                      isDarkMode
                        ? 'bg-neutral-900 border-neutral-800 focus:border-white'
                        : 'bg-neutral-50 border-neutral-300 focus:border-black'
                    } outline-none transition`}
                  />
                </div>

                <div className="flex items-center justify-between text-xs pt-1">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" defaultChecked className="rounded border-neutral-700 accent-black" />
                    <span>Remember me</span>
                  </label>
                  <button onClick={() => setAuthState('forgot')} className="font-semibold underline">
                    Forgot Password?
                  </button>
                </div>

                <div className="pt-4">
                  <button
                    onClick={() => setAuthState('authenticated')}
                    className={`w-full py-3.5 rounded-xl font-semibold text-sm ${
                      isDarkMode ? 'bg-white text-black hover:bg-neutral-200' : 'bg-black text-white hover:bg-neutral-800'
                    }`}
                  >
                    Login
                  </button>
                </div>
              </div>
            </div>
          )}

          {authState === 'forgot' && (
            <div className="flex-1 flex flex-col p-6">
              <button
                onClick={() => setAuthState('login')}
                className="self-start p-2 -ml-2 text-neutral-400 hover:text-neutral-100 mb-4"
              >
                <ArrowLeft size={18} />
              </button>
              <h2 className="text-2xl font-bold tracking-tight">Reset Password</h2>
              <p className={`text-xs mt-1 mb-6 ${isDarkMode ? 'text-neutral-400' : 'text-neutral-600'}`}>
                Enter your university email to receive password reset instructions.
              </p>
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold mb-1.5">Email / Reg Number</label>
                  <input
                    type="text"
                    defaultValue="sp24-bce-042@isb.comsats.edu.pk"
                    className={`w-full px-3.5 py-3 rounded-xl text-sm border ${
                      isDarkMode ? 'bg-neutral-900 border-neutral-800' : 'bg-neutral-50 border-neutral-300'
                    } outline-none`}
                  />
                </div>
                <button
                  onClick={() => {
                    triggerToast('If the account exists, password reset instructions have been sent.');
                    setAuthState('login');
                  }}
                  className={`w-full py-3.5 rounded-xl font-semibold text-sm ${
                    isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                  }`}
                >
                  Send Reset Instructions
                </button>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* AUTHENTICATED TABS & FLOW */}
          {/* ========================================================= */}
          {authState === 'authenticated' && (
            <div className="flex-1 flex flex-col overflow-hidden">
              {/* SCREEN 1: HOME DASHBOARD */}
              {activeTab === 'home' && (
                <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
                  {/* Top Bar: Student Greeting & Notification Badge */}
                  <div className="flex items-start justify-between">
                    <div>
                      <h2 className="text-xl font-extrabold tracking-tight">
                        Good Morning, {student.name.split(' ')[0]}
                      </h2>
                      <p className={`text-xs mt-0.5 leading-snug ${isDarkMode ? 'text-neutral-400' : 'text-neutral-600'}`}>
                        BCE • {student.semester}rd Semester • COMSATS University
                      </p>
                    </div>

                    <button
                      onClick={() => setShowNotificationsScreen(true)}
                      className={`relative p-2.5 rounded-xl border ${
                        isDarkMode
                          ? 'border-neutral-800 bg-neutral-900 text-neutral-200'
                          : 'border-neutral-200 bg-neutral-50 text-neutral-800'
                      }`}
                    >
                      <Bell size={18} />
                      {unreadNotifCount > 0 && (
                        <span className="absolute -top-1 -right-1 w-4 h-4 bg-white text-black font-extrabold text-[9px] rounded-full flex items-center justify-center">
                          {unreadNotifCount}
                        </span>
                      )}
                    </button>
                  </div>

                  {/* Registration Status Card */}
                  <div className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'} space-y-3`}>
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-xs uppercase font-mono tracking-wider text-neutral-400">Course Registration</div>
                        <div className="text-base font-bold tracking-tight">Fall 2026 Semester</div>
                      </div>
                      <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold tracking-wider uppercase border ${
                        isRegistrationOpen
                          ? isDarkMode ? 'bg-white text-black border-white' : 'bg-black text-white border-black'
                          : 'bg-red-500/20 text-red-400 border-red-500/30'
                      }`}>
                        {isRegistrationOpen ? '● OPEN' : 'CLOSED'}
                      </span>
                    </div>

                    <div className={`p-3 rounded-xl flex items-center gap-2.5 text-xs ${isDarkMode ? 'bg-[#1a1a1a]' : 'bg-neutral-50'}`}>
                      <Clock size={16} className="text-neutral-400 shrink-0" />
                      <div>
                        <div className="text-neutral-400 text-[10px]">Registration Deadline</div>
                        <div className="font-semibold">{registrationDeadline}</div>
                      </div>
                    </div>

                    <button
                      onClick={() => setActiveTab('courses')}
                      disabled={!isRegistrationOpen}
                      className={`w-full py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition ${
                        isRegistrationOpen
                          ? isDarkMode ? 'bg-white text-black hover:bg-neutral-200' : 'bg-black text-white hover:bg-neutral-800'
                          : 'bg-neutral-800 text-neutral-500 cursor-not-allowed'
                      }`}
                    >
                      {isRegistrationOpen ? 'Register Courses' : 'Registration Closed'}
                    </button>
                  </div>

                  {/* Credit Hours Card */}
                  <div className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'} space-y-2.5`}>
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-neutral-400">Registered Credit Hours</span>
                      <span className="font-mono font-semibold">{totalRegisteredCredits} / {maxCreditHours} CH</span>
                    </div>

                    {/* Progress Bar */}
                    <div className={`w-full h-2 rounded-full overflow-hidden ${isDarkMode ? 'bg-neutral-800' : 'bg-neutral-200'}`}>
                      <div
                        className={`h-full rounded-full transition-all duration-300 ${isDarkMode ? 'bg-white' : 'bg-black'}`}
                        style={{ width: `${Math.min(100, (totalRegisteredCredits / maxCreditHours) * 100)}%` }}
                      />
                    </div>

                    <div className="flex justify-between text-[11px] text-neutral-400 pt-0.5">
                      <span>Min: {minCreditHours} CH (Satisfied)</span>
                      <span>Max: {maxCreditHours} CH</span>
                    </div>
                  </div>

                  {/* Quick Actions Grid */}
                  <div>
                    <h3 className="text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">Quick Actions</h3>
                    <div className="grid grid-cols-2 gap-2">
                      <button
                        onClick={() => setActiveTab('courses')}
                        className={`p-3 rounded-xl border text-left flex items-center gap-2.5 transition ${
                          isDarkMode ? 'bg-[#141414] border-neutral-800 hover:bg-neutral-800' : 'bg-white border-neutral-200 hover:bg-neutral-50'
                        }`}
                      >
                        <BookOpen size={16} />
                        <div>
                          <div className="text-xs font-semibold">Register Courses</div>
                          <div className="text-[10px] text-neutral-400">Add new courses</div>
                        </div>
                      </button>

                      <button
                        onClick={() => setShowMyCoursesScreen(true)}
                        className={`p-3 rounded-xl border text-left flex items-center gap-2.5 transition ${
                          isDarkMode ? 'bg-[#141414] border-neutral-800 hover:bg-neutral-800' : 'bg-white border-neutral-200 hover:bg-neutral-50'
                        }`}
                      >
                        <CheckCircle2 size={16} />
                        <div>
                          <div className="text-xs font-semibold">My Courses</div>
                          <div className="text-[10px] text-neutral-400">{registrations.length} enrolled</div>
                        </div>
                      </button>

                      <button
                        onClick={() => setActiveTab('timetable')}
                        className={`p-3 rounded-xl border text-left flex items-center gap-2.5 transition ${
                          isDarkMode ? 'bg-[#141414] border-neutral-800 hover:bg-neutral-800' : 'bg-white border-neutral-200 hover:bg-neutral-50'
                        }`}
                      >
                        <Calendar size={16} />
                        <div>
                          <div className="text-xs font-semibold">Timetable</div>
                          <div className="text-[10px] text-neutral-400">Class schedules</div>
                        </div>
                      </button>

                      <button
                        onClick={() => setActiveTab('academic')}
                        className={`p-3 rounded-xl border text-left flex items-center gap-2.5 transition ${
                          isDarkMode ? 'bg-[#141414] border-neutral-800 hover:bg-neutral-800' : 'bg-white border-neutral-200 hover:bg-neutral-50'
                        }`}
                      >
                        <GraduationCap size={16} />
                        <div>
                          <div className="text-xs font-semibold">Academic Record</div>
                          <div className="text-[10px] text-neutral-400">CGPA: {student.cgpa}</div>
                        </div>
                      </button>
                    </div>
                  </div>

                  {/* Today's Timetable Section */}
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-xs font-bold uppercase tracking-wider text-neutral-400">Today's Classes (Monday)</h3>
                      <button onClick={() => setActiveTab('timetable')} className="text-xs font-semibold underline">
                        View Timetable
                      </button>
                    </div>

                    <div className="space-y-2">
                      {getTimetableForDay('Monday').length === 0 ? (
                        <div className={`p-4 rounded-xl border text-center text-xs text-neutral-400 ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                          No classes scheduled for today.
                        </div>
                      ) : (
                        getTimetableForDay('Monday').map((entry, idx) => (
                          <div
                            key={idx}
                            className={`p-3.5 rounded-xl border flex items-center justify-between text-xs ${
                              isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
                            }`}
                          >
                            <div className="space-y-1">
                              <div className="flex items-center gap-2">
                                <span className={`px-1.5 py-0.5 rounded font-mono font-bold text-[10px] ${isDarkMode ? 'bg-white text-black' : 'bg-black text-white'}`}>
                                  {entry.course.code}
                                </span>
                                <span className="font-semibold">{entry.course.title}</span>
                              </div>
                              <div className="text-[11px] text-neutral-400 flex items-center gap-3">
                                <span>{entry.section.sectionName} • {entry.instructor}</span>
                                <span className="flex items-center gap-1"><MapPin size={11} /> {entry.room}</span>
                              </div>
                            </div>

                            <div className="text-right font-mono text-[11px]">
                              <div className="font-bold">{entry.startTime}</div>
                              <div className="text-neutral-400">{entry.endTime}</div>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* SCREEN 2: COURSE REGISTRATION */}
              {activeTab === 'courses' && (
                <div className="flex-1 overflow-y-auto px-5 py-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <h2 className="text-xl font-bold tracking-tight">Course Registration</h2>
                      <p className="text-xs text-neutral-400">Fall 2026 Semester</p>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => setShowRegistrationSummaryModal(true)}
                        className={`px-2.5 py-1.5 rounded-lg border text-xs font-medium flex items-center gap-1 ${
                          isDarkMode ? 'border-neutral-800 bg-neutral-900' : 'border-neutral-200 bg-neutral-50'
                        }`}
                        title="Registration Summary"
                      >
                        Summary
                      </button>

                      <button
                        onClick={() => setShowMyCoursesScreen(true)}
                        className={`px-2.5 py-1.5 rounded-lg border text-xs font-medium flex items-center gap-1 ${
                          isDarkMode ? 'border-neutral-800 bg-neutral-900' : 'border-neutral-200 bg-neutral-50'
                        }`}
                      >
                        My Courses ({registrations.length})
                      </button>
                    </div>
                  </div>

                  {/* Registered vs Available Credit Strip */}
                  <div className={`px-3 py-2 rounded-xl border flex items-center justify-between text-xs ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-neutral-50 border-neutral-200'}`}>
                    <span>Registered: <strong>{totalRegisteredCredits} CH</strong></span>
                    <span>Available: <strong>{availableCredits} CH</strong></span>
                    <span className="text-neutral-400">Max: {maxCreditHours} CH</span>
                  </div>

                  {/* Search & Filter Bar */}
                  <div className="flex items-center gap-2">
                    <div className={`flex-1 flex items-center gap-2 px-3 py-2 rounded-xl border ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                      <Search size={15} className="text-neutral-400" />
                      <input
                        type="text"
                        placeholder="Search by code, title or dept..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="bg-transparent text-xs outline-none w-full placeholder:text-neutral-500"
                      />
                      {searchQuery && (
                        <button onClick={() => setSearchQuery('')}>
                          <X size={13} className="text-neutral-400" />
                        </button>
                      )}
                    </div>

                    <button
                      onClick={() => setShowFilterDrawer(true)}
                      className={`p-2 rounded-xl border ${
                        selectedDept !== 'All' || selectedType !== 'All' || selectedCredits !== null
                          ? isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                          : isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
                      }`}
                      title="Filter courses"
                    >
                      <Filter size={16} />
                    </button>
                  </div>

                  {/* Course List */}
                  <div className="space-y-3 pt-1">
                    {filteredCourses.length === 0 ? (
                      <div className="text-center py-10 text-neutral-400 text-xs">
                        No courses found matching your criteria.
                      </div>
                    ) : (
                      filteredCourses.map((course) => {
                        const isRegistered = registrations.some((r) => r.courseCode === course.code);
                        const prereq = checkPrerequisites(course);
                        const courseSections = sections.filter((s) => s.courseCode === course.code);
                        const availableSecCount = courseSections.filter((s) => s.availableSeats > 0).length;

                        return (
                          <div
                            key={course.code}
                            className={`p-4 rounded-2xl border transition ${
                              isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
                            }`}
                          >
                            <div className="flex items-start justify-between">
                              <div className="space-y-1">
                                <div className="flex items-center gap-2">
                                  <span className={`px-2 py-0.5 rounded font-mono font-bold text-xs ${isDarkMode ? 'bg-white text-black' : 'bg-black text-white'}`}>
                                    {course.code}
                                  </span>
                                  <span className={`text-[11px] px-2 py-0.5 rounded font-medium ${isDarkMode ? 'bg-neutral-800 text-neutral-300' : 'bg-neutral-100 text-neutral-700'}`}>
                                    {course.creditHours} CH
                                  </span>
                                  <span className="text-[10px] text-neutral-400 uppercase font-mono">{course.courseType}</span>
                                </div>
                                <h4 className="text-sm font-bold pt-1">{course.title}</h4>
                                <p className="text-[11px] text-neutral-400">{course.department}</p>
                              </div>

                              {isRegistered ? (
                                <span className={`px-2 py-1 rounded-md text-[10px] font-bold flex items-center gap-1 ${
                                  isDarkMode ? 'bg-white/10 text-white' : 'bg-black/10 text-black'
                                }`}>
                                  <Check size={12} /> Registered
                                </span>
                              ) : (
                                <span className="text-[11px] text-neutral-400">
                                  {availableSecCount} Sec Available
                                </span>
                              )}
                            </div>

                            {/* Prerequisite Indicator */}
                            <div className="flex items-center gap-1.5 mt-3 text-[11px]">
                              {prereq.passed ? (
                                <span className="text-neutral-400 flex items-center gap-1">
                                  <CheckCircle2 size={12} /> {course.prerequisites.length === 0 ? 'No Prerequisites' : 'Prerequisites Satisfied'}
                                </span>
                              ) : (
                                <span className="text-red-400 flex items-center gap-1 font-medium">
                                  <AlertTriangle size={12} /> {prereq.message}
                                </span>
                              )}
                            </div>

                            {/* Action Buttons */}
                            <div className="flex items-center justify-between pt-3 mt-3 border-t border-neutral-800/60 text-xs">
                              <button
                                onClick={() => setSelectedCourseForDetails(course)}
                                className="font-semibold underline text-neutral-400 hover:text-white"
                              >
                                View Details
                              </button>

                              <button
                                onClick={() => {
                                  if (!prereq.passed) {
                                    setErrorDialog(`You cannot register for ${course.code} because the required prerequisite (${course.prerequisites.join(', ')}) has not been completed.`);
                                    return;
                                  }
                                  setSelectedCourseForSections(course);
                                  setIsChangingSectionMode(false);
                                }}
                                disabled={isRegistered}
                                className={`px-3 py-1.5 rounded-lg font-semibold text-xs transition ${
                                  isRegistered
                                    ? 'bg-neutral-800 text-neutral-500 cursor-not-allowed'
                                    : isDarkMode ? 'bg-white text-black hover:bg-neutral-200' : 'bg-black text-white hover:bg-neutral-800'
                                }`}
                              >
                                {isRegistered ? 'Enrolled' : 'View Sections'}
                              </button>
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>
              )}

              {/* SCREEN 3: TIMETABLE */}
              {activeTab === 'timetable' && (
                <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h2 className="text-xl font-bold tracking-tight">Timetable</h2>
                      <p className="text-xs text-neutral-400">Fall 2026 Class Schedule</p>
                    </div>

                    <button
                      onClick={() => setTimetableMode(timetableMode === 'day' ? 'week' : 'day')}
                      className={`px-3 py-1.5 rounded-lg border text-xs font-semibold ${
                        isDarkMode ? 'border-neutral-800 bg-[#141414]' : 'border-neutral-200 bg-white'
                      }`}
                    >
                      {timetableMode === 'day' ? 'Week View' : 'Day View'}
                    </button>
                  </div>

                  {timetableMode === 'day' ? (
                    <>
                      {/* Day Selector Pills */}
                      <div className="flex gap-1.5 overflow-x-auto pb-1">
                        {['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) => (
                          <button
                            key={day}
                            onClick={() => setSelectedTimetableDay(day)}
                            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition shrink-0 ${
                              selectedTimetableDay === day
                                ? isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                                : isDarkMode ? 'bg-[#141414] text-neutral-400' : 'bg-neutral-100 text-neutral-600'
                            }`}
                          >
                            {day}
                          </button>
                        ))}
                      </div>

                      {/* Day's Entries */}
                      <div className="space-y-2.5 pt-1">
                        {getTimetableForDay(selectedTimetableDay).length === 0 ? (
                          <div className={`p-8 rounded-2xl border text-center text-xs text-neutral-400 ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                            No classes scheduled on {selectedTimetableDay}.
                          </div>
                        ) : (
                          getTimetableForDay(selectedTimetableDay).map((entry, idx) => (
                            <div
                              key={idx}
                              className={`p-4 rounded-2xl border flex items-start gap-4 ${
                                isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
                              }`}
                            >
                              <div className={`p-2.5 rounded-xl text-center shrink-0 font-mono ${isDarkMode ? 'bg-neutral-800 text-white' : 'bg-neutral-100 text-black'}`}>
                                <div className="text-xs font-bold">{entry.startTime.split(' ')[0]}</div>
                                <div className="text-[10px] text-neutral-400">{entry.startTime.split(' ')[1]}</div>
                                <div className="text-[10px] mt-1 text-neutral-400">{entry.endTime}</div>
                              </div>

                              <div className="flex-1 space-y-1">
                                <div className="flex items-center justify-between">
                                  <span className={`px-2 py-0.5 rounded font-mono font-bold text-xs ${isDarkMode ? 'bg-white text-black' : 'bg-black text-white'}`}>
                                    {entry.course.code}
                                  </span>
                                  <span className="text-xs text-neutral-400 font-medium">{entry.section.sectionName}</span>
                                </div>
                                <h4 className="text-sm font-bold pt-0.5">{entry.course.title}</h4>
                                <div className="text-xs text-neutral-400 flex items-center gap-3 pt-1">
                                  <span>{entry.instructor}</span>
                                  <span className="flex items-center gap-1"><MapPin size={12} /> {entry.room}</span>
                                </div>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    </>
                  ) : (
                    /* Week View */
                    <div className="space-y-4">
                      {['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) => {
                        const entries = getTimetableForDay(day);
                        return (
                          <div key={day} className="space-y-2">
                            <h4 className="text-xs font-bold uppercase tracking-wider text-neutral-400 flex items-center justify-between">
                              <span>{day}</span>
                              <span className="font-mono text-[10px]">{entries.length} classes</span>
                            </h4>

                            {entries.length === 0 ? (
                              <div className="text-xs text-neutral-500 pl-2">No classes</div>
                            ) : (
                              entries.map((entry, idx) => (
                                <div
                                  key={idx}
                                  className={`p-3 rounded-xl border flex items-center justify-between text-xs ${
                                    isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
                                  }`}
                                >
                                  <div>
                                    <span className="font-mono font-bold mr-2">{entry.course.code}</span>
                                    <span className="font-semibold">{entry.course.title}</span>
                                    <div className="text-[10px] text-neutral-400">{entry.section.sectionName} • {entry.room}</div>
                                  </div>
                                  <div className="text-right font-mono text-[11px] font-bold">
                                    {entry.startTime} - {entry.endTime}
                                  </div>
                                </div>
                              ))
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              )}

              {/* SCREEN 4: ACADEMIC RECORD */}
              {activeTab === 'academic' && (
                <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
                  <div>
                    <h2 className="text-xl font-bold tracking-tight">Academic Record</h2>
                    <p className="text-xs text-neutral-400">Cumulative GPA & Semester History</p>
                  </div>

                  {/* Summary Cards */}
                  <div className="grid grid-cols-2 gap-3">
                    <div className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                      <div className="text-[11px] text-neutral-400">Cumulative GPA</div>
                      <div className="text-2xl font-black mt-1 font-mono">{student.cgpa}</div>
                      <div className="text-[10px] text-neutral-500">out of 4.00</div>
                    </div>

                    <div className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                      <div className="text-[11px] text-neutral-400">Completed Credits</div>
                      <div className="text-2xl font-black mt-1 font-mono">{student.completedCreditHours}</div>
                      <div className="text-[10px] text-neutral-500">of 134 CH required</div>
                    </div>
                  </div>

                  {/* Student Details Card */}
                  <div className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'} space-y-2 text-xs`}>
                    <div className="flex justify-between py-1 border-b border-neutral-800/40">
                      <span className="text-neutral-400">Registration Number</span>
                      <span className="font-mono font-semibold">{student.registrationNumber}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-neutral-800/40">
                      <span className="text-neutral-400">Program</span>
                      <span className="font-semibold">{student.program}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-neutral-800/40">
                      <span className="text-neutral-400">Campus</span>
                      <span className="font-semibold">{student.campus}</span>
                    </div>
                    <div className="flex justify-between py-1">
                      <span className="text-neutral-400">Academic Standing</span>
                      <span className="font-bold text-emerald-400">{student.academicStanding}</span>
                    </div>
                  </div>

                  {/* Semester History */}
                  <div>
                    <h3 className="text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">Previous Semesters</h3>
                    <div className="space-y-2.5">
                      {mockSemesterHistory.map((sem, idx) => (
                        <div
                          key={idx}
                          onClick={() => setSelectedSemesterModal(sem)}
                          className={`p-3.5 rounded-2xl border flex items-center justify-between cursor-pointer transition ${
                            isDarkMode ? 'bg-[#141414] border-neutral-800 hover:bg-neutral-800/60' : 'bg-white border-neutral-200 hover:bg-neutral-50'
                          }`}
                        >
                          <div>
                            <div className="text-sm font-bold">{sem.semester}</div>
                            <div className="text-xs text-neutral-400">{sem.creditHours} Credit Hours • {sem.courses.length} Courses</div>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-neutral-800 text-neutral-200">
                              GPA {sem.gpa}
                            </span>
                            <ChevronRight size={14} className="text-neutral-400" />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* SCREEN 5: PROFILE */}
              {activeTab === 'profile' && (
                <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
                  <div className="flex items-center justify-between">
                    <h2 className="text-xl font-bold tracking-tight">Student Profile</h2>
                    <button
                      onClick={() => setShowEditProfileModal(true)}
                      className={`p-2 rounded-xl border text-xs flex items-center gap-1 font-semibold ${
                        isDarkMode ? 'border-neutral-800 bg-[#141414]' : 'border-neutral-200 bg-white'
                      }`}
                    >
                      <Edit3 size={14} /> Edit
                    </button>
                  </div>

                  {/* Profile Card */}
                  <div className={`p-4 rounded-2xl border text-center ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                    <div className={`w-16 h-16 rounded-full mx-auto flex items-center justify-center font-black text-xl mb-3 ${
                      isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                    }`}>
                      {student.name.charAt(0)}
                    </div>
                    <h3 className="text-base font-bold">{student.name}</h3>
                    <p className="text-xs font-mono text-neutral-400 mt-0.5">{student.registrationNumber}</p>
                    <p className="text-xs text-neutral-500 mt-1">{student.email}</p>
                  </div>

                  {/* Information Sections */}
                  <div className="space-y-3 text-xs">
                    <div className={`p-4 rounded-2xl border space-y-2.5 ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                      <h4 className="font-bold uppercase tracking-wider text-[11px] text-neutral-400 mb-1">Student Information</h4>
                      <div className="flex justify-between"><span className="text-neutral-400">Phone Number</span><span>{student.phoneNumber}</span></div>
                      <div className="flex justify-between"><span className="text-neutral-400">Program</span><span>{student.program}</span></div>
                      <div className="flex justify-between"><span className="text-neutral-400">Campus</span><span>{student.campus}</span></div>
                      <div className="flex justify-between"><span className="text-neutral-400">Batch</span><span>{student.batch}</span></div>
                    </div>

                    <div className={`p-4 rounded-2xl border space-y-2.5 ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                      <h4 className="font-bold uppercase tracking-wider text-[11px] text-neutral-400 mb-1">Academic Status</h4>
                      <div className="flex justify-between"><span className="text-neutral-400">Current Semester</span><span>{student.semester}rd Semester</span></div>
                      <div className="flex justify-between"><span className="text-neutral-400">CGPA</span><span className="font-mono font-bold">{student.cgpa} / 4.00</span></div>
                      <div className="flex justify-between"><span className="text-neutral-400">Credits Completed</span><span>{student.completedCreditHours} CH</span></div>
                    </div>

                    <div className={`p-4 rounded-2xl border space-y-3 ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'}`}>
                      <h4 className="font-bold uppercase tracking-wider text-[11px] text-neutral-400">Preferences & Controls</h4>
                      <div className="flex items-center justify-between">
                        <span>Registration Period Control (Admin Demo)</span>
                        <button
                          onClick={() => {
                            setIsRegistrationOpen(!isRegistrationOpen);
                            triggerToast(`Registration is now ${!isRegistrationOpen ? 'OPEN' : 'CLOSED'}`);
                          }}
                          className={`px-2.5 py-1 rounded-md text-[11px] font-bold ${
                            isRegistrationOpen ? 'bg-emerald-500/20 text-emerald-400' : 'bg-red-500/20 text-red-400'
                          }`}
                        >
                          {isRegistrationOpen ? 'OPEN' : 'CLOSED'}
                        </button>
                      </div>

                      <div className="flex items-center justify-between">
                        <span>Dark Theme</span>
                        <button
                          onClick={() => setIsDarkMode(!isDarkMode)}
                          className="px-2.5 py-1 rounded-md text-[11px] font-bold border border-neutral-700"
                        >
                          {isDarkMode ? 'ON' : 'OFF'}
                        </button>
                      </div>
                    </div>

                    <button
                      onClick={() => setAuthState('welcome')}
                      className={`w-full py-3 rounded-xl border text-xs font-bold flex items-center justify-center gap-2 ${
                        isDarkMode ? 'border-red-900/40 text-red-400 bg-red-950/20' : 'border-red-200 text-red-600 bg-red-50'
                      }`}
                    >
                      <LogOut size={14} /> Log Out
                    </button>
                  </div>
                </div>
              )}

              {/* ========================================================= */}
              {/* NATIVE BOTTOM NAVIGATION BAR (Flutter NavigationBar Mirror) */}
              {/* ========================================================= */}
              <nav className={`border-t ${isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'} px-2 py-2 flex items-center justify-around shrink-0`}>
                <button
                  onClick={() => setActiveTab('home')}
                  className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
                    activeTab === 'home'
                      ? isDarkMode ? 'text-white' : 'text-black'
                      : 'text-neutral-500 hover:text-neutral-400'
                  }`}
                >
                  <Home size={18} strokeWidth={activeTab === 'home' ? 2.5 : 1.75} />
                  <span className={`text-[10px] ${activeTab === 'home' ? 'font-bold' : 'font-medium'}`}>Home</span>
                </button>

                <button
                  onClick={() => setActiveTab('courses')}
                  className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
                    activeTab === 'courses'
                      ? isDarkMode ? 'text-white' : 'text-black'
                      : 'text-neutral-500 hover:text-neutral-400'
                  }`}
                >
                  <BookOpen size={18} strokeWidth={activeTab === 'courses' ? 2.5 : 1.75} />
                  <span className={`text-[10px] ${activeTab === 'courses' ? 'font-bold' : 'font-medium'}`}>Courses</span>
                </button>

                <button
                  onClick={() => setActiveTab('timetable')}
                  className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
                    activeTab === 'timetable'
                      ? isDarkMode ? 'text-white' : 'text-black'
                      : 'text-neutral-500 hover:text-neutral-400'
                  }`}
                >
                  <Calendar size={18} strokeWidth={activeTab === 'timetable' ? 2.5 : 1.75} />
                  <span className={`text-[10px] ${activeTab === 'timetable' ? 'font-bold' : 'font-medium'}`}>Timetable</span>
                </button>

                <button
                  onClick={() => setActiveTab('academic')}
                  className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
                    activeTab === 'academic'
                      ? isDarkMode ? 'text-white' : 'text-black'
                      : 'text-neutral-500 hover:text-neutral-400'
                  }`}
                >
                  <GraduationCap size={18} strokeWidth={activeTab === 'academic' ? 2.5 : 1.75} />
                  <span className={`text-[10px] ${activeTab === 'academic' ? 'font-bold' : 'font-medium'}`}>Academic</span>
                </button>

                <button
                  onClick={() => setActiveTab('profile')}
                  className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
                    activeTab === 'profile'
                      ? isDarkMode ? 'text-white' : 'text-black'
                      : 'text-neutral-500 hover:text-neutral-400'
                  }`}
                >
                  <User size={18} strokeWidth={activeTab === 'profile' ? 2.5 : 1.75} />
                  <span className={`text-[10px] ${activeTab === 'profile' ? 'font-bold' : 'font-medium'}`}>Profile</span>
                </button>
              </nav>
            </div>
          )}

          {/* ========================================================= */}
          {/* MODAL 1: SECTION SELECTION SCREEN */}
          {/* ========================================================= */}
          {selectedCourseForSections && (
            <div className="absolute inset-0 z-40 bg-black/80 flex flex-col justify-end animate-in fade-in duration-150">
              <div
                className={`w-full max-h-[88%] rounded-t-3xl border-t p-5 overflow-y-auto flex flex-col ${
                  isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
                }`}
              >
                <div className="flex items-center justify-between pb-3 border-b border-neutral-800/40">
                  <div>
                    <div className="text-xs uppercase font-mono text-neutral-400">
                      {isChangingSectionMode ? 'Change Section' : 'Available Sections'}
                    </div>
                    <h3 className="text-base font-bold">{selectedCourseForSections.code} - {selectedCourseForSections.title}</h3>
                  </div>
                  <button onClick={() => setSelectedCourseForSections(null)} className="p-1 text-neutral-400 hover:text-white">
                    <X size={18} />
                  </button>
                </div>

                <div className="py-4 space-y-3 flex-1 overflow-y-auto">
                  {sections
                    .filter((s) => s.courseCode === selectedCourseForSections.code)
                    .map((sec) => {
                      const currentReg = registrations.find((r) => r.courseCode === selectedCourseForSections.code);
                      const isCurrentSection = currentReg?.sectionId === sec.id;
                      const conflict = checkScheduleConflict(
                        sec,
                        isChangingSectionMode ? selectedCourseForSections.code : undefined
                      );
                      const isFull = sec.availableSeats <= 0;

                      return (
                        <div
                          key={sec.id}
                          className={`p-4 rounded-2xl border ${
                            isCurrentSection
                              ? isDarkMode ? 'border-white bg-[#1c1c1c]' : 'border-black bg-neutral-50'
                              : conflict.hasConflict
                              ? 'border-red-500/40 bg-red-950/10'
                              : isDarkMode ? 'border-neutral-800 bg-[#181818]' : 'border-neutral-200 bg-white'
                          } space-y-2`}
                        >
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                              <span className="font-bold text-sm">{sec.sectionName}</span>
                              {isCurrentSection && (
                                <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
                                  isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                                }`}>
                                  Current Section
                                </span>
                              )}
                            </div>
                            <span className={`text-[11px] font-mono px-2 py-0.5 rounded ${
                              isFull ? 'bg-red-500/20 text-red-400 font-bold' : 'bg-neutral-800 text-neutral-300'
                            }`}>
                              {isFull ? '0 Seats (Full)' : `${sec.availableSeats} / ${sec.totalSeats} Seats`}
                            </span>
                          </div>

                          <div className="text-xs text-neutral-400 space-y-1">
                            <div className="flex items-center justify-between">
                              <button
                                onClick={() => {
                                  const inst = mockInstructors.find((i) => i.id === sec.instructorId);
                                  if (inst) setSelectedInstructorModal(inst);
                                }}
                                className="font-medium underline decoration-dotted hover:text-white"
                              >
                                {sec.instructor} ⓘ
                              </button>
                              <span className="flex items-center gap-1 font-mono"><MapPin size={11} /> {sec.room}</span>
                            </div>
                            <div className="flex items-center gap-2 text-neutral-300">
                              <Clock size={12} className="text-neutral-500" />
                              <span>{sec.days.join(' / ')} • {sec.startTime} - {sec.endTime}</span>
                            </div>
                          </div>

                          {/* Conflict Message */}
                          {conflict.hasConflict && (
                            <div className="text-[11px] text-red-400 flex items-center gap-1.5 pt-1">
                              <AlertTriangle size={13} className="shrink-0" />
                              <span>{conflict.message}</span>
                            </div>
                          )}

                          {/* Button */}
                          <div className="pt-2">
                            {isChangingSectionMode ? (
                              <button
                                disabled={isCurrentSection || isFull || conflict.hasConflict}
                                onClick={() => handleChangeSection(selectedCourseForSections, sec)}
                                className={`w-full py-2 rounded-xl text-xs font-semibold ${
                                  isCurrentSection
                                    ? 'bg-neutral-800 text-neutral-500 cursor-not-allowed'
                                    : isFull || conflict.hasConflict
                                    ? 'bg-neutral-800 text-neutral-500 cursor-not-allowed'
                                    : isDarkMode ? 'bg-white text-black hover:bg-neutral-200' : 'bg-black text-white hover:bg-neutral-800'
                                }`}
                              >
                                {isCurrentSection ? 'Current Section' : isFull ? 'Section Full' : conflict.hasConflict ? 'Conflict' : 'Switch to this Section'}
                              </button>
                            ) : (
                              <button
                                disabled={isCurrentSection || isFull || conflict.hasConflict}
                                onClick={() => setRegisterConfirmSection({ course: selectedCourseForSections, section: sec })}
                                className={`w-full py-2 rounded-xl text-xs font-semibold ${
                                  isCurrentSection
                                    ? 'bg-neutral-800 text-neutral-500 cursor-not-allowed'
                                    : isFull || conflict.hasConflict
                                    ? 'bg-neutral-800 text-neutral-500 cursor-not-allowed'
                                    : isDarkMode ? 'bg-white text-black hover:bg-neutral-200' : 'bg-black text-white hover:bg-neutral-800'
                                }`}
                              >
                                {isCurrentSection ? 'Already Registered' : isFull ? 'Section Full' : conflict.hasConflict ? 'Schedule Conflict' : 'Select Section'}
                              </button>
                            )}
                          </div>
                        </div>
                      );
                    })}
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* MODAL 2: COURSE DETAILS SCREEN */}
          {/* ========================================================= */}
          {selectedCourseForDetails && (
            <div className="absolute inset-0 z-40 bg-black/80 flex flex-col justify-end animate-in fade-in duration-150">
              <div className={`w-full max-h-[88%] rounded-t-3xl border-t p-5 overflow-y-auto space-y-4 ${
                isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex items-center justify-between pb-3 border-b border-neutral-800/40">
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-0.5 rounded font-mono font-bold text-xs ${isDarkMode ? 'bg-white text-black' : 'bg-black text-white'}`}>
                      {selectedCourseForDetails.code}
                    </span>
                    <span className="text-xs text-neutral-400 font-semibold">{selectedCourseForDetails.creditHours} CH</span>
                  </div>
                  <button onClick={() => setSelectedCourseForDetails(null)} className="p-1 text-neutral-400 hover:text-white">
                    <X size={18} />
                  </button>
                </div>

                <div>
                  <h3 className="text-lg font-bold">{selectedCourseForDetails.title}</h3>
                  <p className="text-xs text-neutral-400">{selectedCourseForDetails.department}</p>
                </div>

                <div className={`p-3 rounded-xl border text-xs space-y-1 ${isDarkMode ? 'bg-[#1c1c1c] border-neutral-800' : 'bg-neutral-50 border-neutral-200'}`}>
                  <div className="font-semibold text-neutral-300">Prerequisite Status</div>
                  {checkPrerequisites(selectedCourseForDetails).passed ? (
                    <div className="text-emerald-400 flex items-center gap-1 font-medium">
                      <CheckCircle2 size={13} /> Prerequisites Completed ({selectedCourseForDetails.prerequisites.length === 0 ? 'None' : selectedCourseForDetails.prerequisites.join(', ')})
                    </div>
                  ) : (
                    <div className="text-red-400 flex items-center gap-1 font-medium">
                      <AlertTriangle size={13} /> Required Prerequisite Missing: {selectedCourseForDetails.prerequisites.join(', ')}
                    </div>
                  )}
                </div>

                <div>
                  <h4 className="text-xs font-bold uppercase tracking-wider text-neutral-400 mb-1">Course Description</h4>
                  <p className="text-xs leading-relaxed text-neutral-300">{selectedCourseForDetails.description}</p>
                </div>

                <div className="space-y-1.5 text-xs text-neutral-400 pt-2 border-t border-neutral-800/40">
                  <div className="flex justify-between"><span>Course Type</span><span className="font-semibold text-neutral-200">{selectedCourseForDetails.courseType}</span></div>
                  <div className="flex justify-between"><span>Recommended Semester</span><span className="font-semibold text-neutral-200">Semester {selectedCourseForDetails.recommendedSemester}</span></div>
                  <div className="flex justify-between"><span>Corequisites</span><span className="font-semibold text-neutral-200">None</span></div>
                </div>

                <div className="pt-2">
                  <button
                    onClick={() => {
                      const course = selectedCourseForDetails;
                      setSelectedCourseForDetails(null);
                      setSelectedCourseForSections(course);
                      setIsChangingSectionMode(false);
                    }}
                    className={`w-full py-3 rounded-xl text-xs font-bold uppercase tracking-wider ${
                      isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                    }`}
                  >
                    View Sections & Register
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* MODAL 3: MY COURSES SCREEN */}
          {/* ========================================================= */}
          {showMyCoursesScreen && (
            <div className="absolute inset-0 z-40 bg-black/80 flex flex-col justify-end animate-in fade-in duration-150">
              <div className={`w-full max-h-[90%] rounded-t-3xl border-t p-5 overflow-y-auto space-y-4 flex flex-col ${
                isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex items-center justify-between pb-3 border-b border-neutral-800/40">
                  <div>
                    <h3 className="text-base font-bold">My Registered Courses</h3>
                    <p className="text-xs text-neutral-400">Fall 2026 • {registrations.length} Enrolled ({totalRegisteredCredits} CH)</p>
                  </div>
                  <button onClick={() => setShowMyCoursesScreen(false)} className="p-1 text-neutral-400 hover:text-white">
                    <X size={18} />
                  </button>
                </div>

                <div className="space-y-3 flex-1 overflow-y-auto">
                  {registrations.length === 0 ? (
                    <div className="text-center py-12 text-neutral-400 text-xs">
                      You haven't registered for any courses yet.
                    </div>
                  ) : (
                    registrations.map((reg) => {
                      const course = mockCourses.find((c) => c.code === reg.courseCode);
                      const sec = sections.find((s) => s.id === reg.sectionId);
                      if (!course || !sec) return null;

                      return (
                        <div
                          key={reg.id}
                          className={`p-4 rounded-2xl border ${isDarkMode ? 'bg-[#1a1a1a] border-neutral-800' : 'bg-neutral-50 border-neutral-200'} space-y-2`}
                        >
                          <div className="flex items-center justify-between">
                            <span className={`px-2 py-0.5 rounded font-mono font-bold text-xs ${isDarkMode ? 'bg-white text-black' : 'bg-black text-white'}`}>
                              {course.code}
                            </span>
                            <span className="font-mono text-xs font-semibold">{course.creditHours} CH</span>
                          </div>

                          <h4 className="text-sm font-bold">{course.title}</h4>
                          <div className="text-xs text-neutral-400 space-y-0.5">
                            <div>{sec.sectionName} • {sec.instructor}</div>
                            <div className="flex items-center gap-2">
                              <span>{sec.days.join(' / ')} • {sec.startTime} - {sec.endTime}</span>
                              <span>({sec.room})</span>
                            </div>
                          </div>

                          <div className="flex items-center justify-end gap-2 pt-2 border-t border-neutral-800/40 text-xs">
                            <button
                              onClick={() => {
                                setSelectedCourseForSections(course);
                                setIsChangingSectionMode(true);
                              }}
                              className="px-2.5 py-1 rounded-lg border border-neutral-700 font-semibold hover:bg-neutral-800"
                            >
                              Change Section
                            </button>
                            <button
                              onClick={() => setDropConfirmCourse({ code: course.code, title: course.title })}
                              className="px-2.5 py-1 rounded-lg border border-red-500/40 text-red-400 font-semibold hover:bg-red-950/20"
                            >
                              Drop Course
                            </button>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* MODAL 4: NOTIFICATIONS SCREEN */}
          {/* ========================================================= */}
          {showNotificationsScreen && (
            <div className="absolute inset-0 z-40 bg-black/80 flex flex-col justify-end animate-in fade-in duration-150">
              <div className={`w-full max-h-[85%] rounded-t-3xl border-t p-5 overflow-y-auto space-y-3 flex flex-col ${
                isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex items-center justify-between pb-3 border-b border-neutral-800/40">
                  <h3 className="text-base font-bold">Notifications</h3>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })))}
                      className="text-xs font-semibold underline text-neutral-400 hover:text-white"
                    >
                      Mark all read
                    </button>
                    <button onClick={() => setShowNotificationsScreen(false)} className="p-1 text-neutral-400 hover:text-white">
                      <X size={18} />
                    </button>
                  </div>
                </div>

                <div className="space-y-2.5 flex-1 overflow-y-auto">
                  {notifications.map((n) => (
                    <div
                      key={n.id}
                      onClick={() => setNotifications((prev) => prev.map((item) => (item.id === n.id ? { ...item, isRead: true } : item)))}
                      className={`p-3.5 rounded-2xl border text-xs cursor-pointer ${
                        n.isRead
                          ? isDarkMode ? 'bg-[#141414] border-neutral-800 text-neutral-400' : 'bg-white border-neutral-200 text-neutral-600'
                          : isDarkMode ? 'bg-[#1c1c1c] border-neutral-700 text-white font-medium' : 'bg-neutral-50 border-neutral-300 text-black font-medium'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-xs">{n.title}</span>
                        <span className="text-[10px] text-neutral-500">{n.time}</span>
                      </div>
                      <p className="mt-1 leading-snug">{n.message}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* CONFIRMATION DIALOG 1: REGISTER COURSE */}
          {/* ========================================================= */}
          {registerConfirmSection && (
            <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-6 animate-in fade-in duration-100">
              <div className={`w-full max-w-sm rounded-2xl border p-5 space-y-4 ${
                isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div>
                  <h3 className="text-base font-bold">Register for {registerConfirmSection.course.code}?</h3>
                  <p className="text-xs text-neutral-400 mt-0.5">{registerConfirmSection.course.title}</p>
                </div>

                <div className="text-xs space-y-1.5 py-2 border-y border-neutral-800/40 text-neutral-300">
                  <div className="flex justify-between">
                    <span className="text-neutral-400">Section</span>
                    <span className="font-bold">{registerConfirmSection.section.sectionName}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-neutral-400">Credit Hours</span>
                    <span className="font-bold">{registerConfirmSection.course.creditHours} CH</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-neutral-400">Current Total</span>
                    <span>{totalRegisteredCredits} CH</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-neutral-400">New Total</span>
                    <span className="font-bold font-mono text-emerald-400">
                      {totalRegisteredCredits + registerConfirmSection.course.creditHours} CH
                    </span>
                  </div>
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={() => setRegisterConfirmSection(null)}
                    className="flex-1 py-2.5 rounded-xl border border-neutral-700 text-xs font-semibold hover:bg-neutral-800"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleRegisterConfirm}
                    className={`flex-1 py-2.5 rounded-xl text-xs font-bold ${
                      isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                    }`}
                  >
                    Confirm Registration
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* CONFIRMATION DIALOG 2: DROP COURSE */}
          {/* ========================================================= */}
          {dropConfirmCourse && (
            <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-6 animate-in fade-in duration-100">
              <div className={`w-full max-w-sm rounded-2xl border p-5 space-y-4 ${
                isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div>
                  <h3 className="text-base font-bold text-red-400">Drop {dropConfirmCourse.code}?</h3>
                  <p className="text-xs text-neutral-400 mt-1">{dropConfirmCourse.title}</p>
                </div>
                <p className="text-xs text-neutral-400 leading-relaxed">
                  This course will be removed from your Fall 2026 semester registration and your credit hours will be recalculated.
                </p>
                <div className="flex gap-2">
                  <button
                    onClick={() => setDropConfirmCourse(null)}
                    className="flex-1 py-2.5 rounded-xl border border-neutral-700 text-xs font-semibold"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleDropConfirm}
                    className="flex-1 py-2.5 rounded-xl bg-red-600 text-white text-xs font-bold hover:bg-red-700"
                  >
                    Drop Course
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* ERROR ALERT DIALOG */}
          {/* ========================================================= */}
          {errorDialog && (
            <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-6 animate-in fade-in duration-100">
              <div className={`w-full max-w-sm rounded-2xl border p-5 space-y-3 ${
                isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex items-center gap-2 text-red-400 font-bold text-sm">
                  <AlertTriangle size={18} />
                  <span>Validation Warning</span>
                </div>
                <p className="text-xs text-neutral-300 leading-relaxed">{errorDialog}</p>
                <button
                  onClick={() => setErrorDialog(null)}
                  className={`w-full py-2.5 rounded-xl text-xs font-bold ${
                    isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                  }`}
                >
                  Understood
                </button>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* INSTRUCTOR DETAILS MODAL */}
          {/* ========================================================= */}
          {selectedInstructorModal && (
            <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-6 animate-in fade-in duration-100">
              <div className={`w-full max-w-sm rounded-2xl border p-5 space-y-3 ${
                isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="text-base font-bold">{selectedInstructorModal.name}</h3>
                    <p className="text-xs text-neutral-400">{selectedInstructorModal.designation}</p>
                  </div>
                  <button onClick={() => setSelectedInstructorModal(null)}>
                    <X size={16} className="text-neutral-400" />
                  </button>
                </div>

                <div className="text-xs space-y-2 py-2 border-y border-neutral-800/40 text-neutral-300">
                  <div><span className="text-neutral-500">Department:</span> {selectedInstructorModal.department}</div>
                  <div><span className="text-neutral-500">Office:</span> {selectedInstructorModal.office}</div>
                  <div><span className="text-neutral-500">Email:</span> {selectedInstructorModal.email}</div>
                  <div>
                    <div className="text-neutral-500 mb-1">Courses Taught:</div>
                    <div className="flex flex-wrap gap-1">
                      {selectedInstructorModal.coursesTaught.map((c, i) => (
                        <span key={i} className="px-1.5 py-0.5 rounded bg-neutral-800 text-[10px]">{c}</span>
                      ))}
                    </div>
                  </div>
                </div>

                <button
                  onClick={() => setSelectedInstructorModal(null)}
                  className="w-full py-2 rounded-xl text-xs font-semibold border border-neutral-700"
                >
                  Close
                </button>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* SEMESTER BREAKDOWN MODAL */}
          {/* ========================================================= */}
          {selectedSemesterModal && (
            <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-6 animate-in fade-in duration-100">
              <div className={`w-full max-w-sm rounded-2xl border p-5 space-y-3 max-h-[85%] overflow-y-auto ${
                isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="text-base font-bold">{selectedSemesterModal.semester}</h3>
                    <p className="text-xs text-neutral-400">GPA: {selectedSemesterModal.gpa} • {selectedSemesterModal.creditHours} CH</p>
                  </div>
                  <button onClick={() => setSelectedSemesterModal(null)}>
                    <X size={16} className="text-neutral-400" />
                  </button>
                </div>

                <div className="space-y-2 pt-2">
                  {selectedSemesterModal.courses.map((c, i) => (
                    <div key={i} className="flex items-center justify-between text-xs p-2 rounded-lg bg-neutral-800/40">
                      <div>
                        <div className="font-mono font-bold">{c.code}</div>
                        <div className="text-[11px] text-neutral-400">{c.title} ({c.ch} CH)</div>
                      </div>
                      <span className="font-mono font-black text-sm px-2 py-0.5 rounded bg-white text-black">
                        {c.grade}
                      </span>
                    </div>
                  ))}
                </div>

                <button
                  onClick={() => setSelectedSemesterModal(null)}
                  className="w-full py-2 rounded-xl text-xs font-semibold border border-neutral-700 mt-2"
                >
                  Close
                </button>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* REGISTRATION SUMMARY MODAL */}
          {/* ========================================================= */}
          {showRegistrationSummaryModal && (
            <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-6 animate-in fade-in duration-100">
              <div className={`w-full max-w-sm rounded-2xl border p-5 space-y-3 max-h-[85%] overflow-y-auto ${
                isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="text-base font-bold">Registration Summary</h3>
                    <p className="text-xs text-neutral-400">Fall 2026 Semester Official Slip</p>
                  </div>
                  <button onClick={() => setShowRegistrationSummaryModal(false)}>
                    <X size={16} className="text-neutral-400" />
                  </button>
                </div>

                <div className="space-y-2 py-2 border-y border-neutral-800/40 text-xs">
                  {registrations.map((reg) => {
                    const c = mockCourses.find((course) => course.code === reg.courseCode);
                    const s = sections.find((sec) => sec.id === reg.sectionId);
                    return (
                      <div key={reg.id} className="flex justify-between items-center py-1">
                        <div>
                          <span className="font-mono font-bold">{reg.courseCode}</span> ({s?.sectionName})
                          <div className="text-[10px] text-neutral-400">{c?.title}</div>
                        </div>
                        <span className="font-mono font-bold">{c?.creditHours} CH</span>
                      </div>
                    );
                  })}
                  <div className="flex justify-between pt-2 border-t border-neutral-800/60 font-bold">
                    <span>Total Registered</span>
                    <span>{totalRegisteredCredits} / {maxCreditHours} CH</span>
                  </div>
                </div>

                <button
                  onClick={() => {
                    setShowRegistrationSummaryModal(false);
                    triggerToast('Fall 2026 registration verified and confirmed!');
                  }}
                  className={`w-full py-2.5 rounded-xl text-xs font-bold ${
                    isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                  }`}
                >
                  Confirm & Save Registration
                </button>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* EDIT PROFILE MODAL */}
          {/* ========================================================= */}
          {showEditProfileModal && (
            <div className="absolute inset-0 z-50 bg-black/80 flex items-center justify-center p-6 animate-in fade-in duration-100">
              <div className={`w-full max-w-sm rounded-2xl border p-5 space-y-3 ${
                isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex justify-between items-start">
                  <h3 className="text-base font-bold">Edit Profile</h3>
                  <button onClick={() => setShowEditProfileModal(false)}>
                    <X size={16} className="text-neutral-400" />
                  </button>
                </div>

                <div className="space-y-3 text-xs">
                  <div>
                    <label className="block text-neutral-400 mb-1">Display Name</label>
                    <input
                      type="text"
                      defaultValue={student.name}
                      id="edit-name"
                      className={`w-full px-3 py-2 rounded-xl border ${
                        isDarkMode ? 'bg-neutral-900 border-neutral-800' : 'bg-neutral-50 border-neutral-300'
                      }`}
                    />
                  </div>
                  <div>
                    <label className="block text-neutral-400 mb-1">Phone Number</label>
                    <input
                      type="text"
                      defaultValue={student.phoneNumber}
                      id="edit-phone"
                      className={`w-full px-3 py-2 rounded-xl border ${
                        isDarkMode ? 'bg-neutral-900 border-neutral-800' : 'bg-neutral-50 border-neutral-300'
                      }`}
                    />
                  </div>
                  <div className="text-[10px] text-neutral-500">
                    Registration Number ({student.registrationNumber}) and Degree Program are locked by registrar.
                  </div>
                </div>

                <div className="flex gap-2 pt-2">
                  <button
                    onClick={() => setShowEditProfileModal(false)}
                    className="flex-1 py-2 rounded-xl border border-neutral-700 text-xs font-semibold"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => {
                      const nameInput = (document.getElementById('edit-name') as HTMLInputElement)?.value;
                      const phoneInput = (document.getElementById('edit-phone') as HTMLInputElement)?.value;
                      setStudent((prev) => ({
                        ...prev,
                        name: nameInput || prev.name,
                        phoneNumber: phoneInput || prev.phoneNumber,
                      }));
                      setShowEditProfileModal(false);
                      triggerToast('Profile updated successfully.');
                    }}
                    className={`flex-1 py-2 rounded-xl text-xs font-bold ${
                      isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                    }`}
                  >
                    Save Changes
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* COURSE FILTER DRAWER */}
          {/* ========================================================= */}
          {showFilterDrawer && (
            <div className="absolute inset-0 z-40 bg-black/80 flex flex-col justify-end animate-in fade-in duration-150">
              <div className={`w-full max-h-[85%] rounded-t-3xl border-t p-5 overflow-y-auto space-y-4 ${
                isDarkMode ? 'bg-[#141414] border-neutral-800' : 'bg-white border-neutral-200'
              }`}>
                <div className="flex items-center justify-between pb-2 border-b border-neutral-800/40">
                  <h3 className="text-base font-bold">Filter Courses</h3>
                  <button
                    onClick={() => {
                      setSelectedDept('All');
                      setSelectedType('All');
                      setSelectedCredits(null);
                    }}
                    className="text-xs font-semibold underline text-neutral-400"
                  >
                    Reset
                  </button>
                </div>

                {/* Dept */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">Department</label>
                  <div className="flex flex-wrap gap-1.5">
                    {['All', 'Computer Science', 'Computer Engineering', 'Mathematics', 'Humanities'].map((d) => (
                      <button
                        key={d}
                        onClick={() => setSelectedDept(d)}
                        className={`px-2.5 py-1 rounded-lg text-xs font-semibold ${
                          selectedDept === d
                            ? isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                            : isDarkMode ? 'bg-neutral-800 text-neutral-300' : 'bg-neutral-100 text-neutral-700'
                        }`}
                      >
                        {d}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Course Type */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">Course Type</label>
                  <div className="flex flex-wrap gap-1.5">
                    {['All', 'Core', 'Elective', 'University Requirement'].map((t) => (
                      <button
                        key={t}
                        onClick={() => setSelectedType(t)}
                        className={`px-2.5 py-1 rounded-lg text-xs font-semibold ${
                          selectedType === t
                            ? isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                            : isDarkMode ? 'bg-neutral-800 text-neutral-300' : 'bg-neutral-100 text-neutral-700'
                        }`}
                      >
                        {t}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Credit Hours */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">Credit Hours</label>
                  <div className="flex gap-1.5">
                    {[null, 3, 4].map((ch) => (
                      <button
                        key={String(ch)}
                        onClick={() => setSelectedCredits(ch)}
                        className={`px-3 py-1 rounded-lg text-xs font-semibold ${
                          selectedCredits === ch
                            ? isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                            : isDarkMode ? 'bg-neutral-800 text-neutral-300' : 'bg-neutral-100 text-neutral-700'
                        }`}
                      >
                        {ch === null ? 'Any' : `${ch} CH`}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="pt-2">
                  <button
                    onClick={() => setShowFilterDrawer(false)}
                    className={`w-full py-2.5 rounded-xl text-xs font-bold ${
                      isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                    }`}
                  >
                    Apply Filters
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* ========================================================= */}
      {/* FLUTTER SOURCE CODE & APK EXPORT DRAWER */}
      {/* ========================================================= */}
      {showFlutterSourceModal && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <div className={`w-full max-w-3xl max-h-[90vh] rounded-3xl border flex flex-col overflow-hidden ${
            isDarkMode ? 'bg-[#121212] border-neutral-800 text-neutral-100' : 'bg-white border-neutral-200 text-neutral-900'
          }`}>
            <div className="px-6 py-4 border-b border-neutral-800/60 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <FileCode2 size={20} />
                <div>
                  <h3 className="font-bold text-sm">COMSATS Flutter & Dart Source Codebase</h3>
                  <p className="text-xs text-neutral-400">All Dart models, widgets, screens, and services are created in /lib</p>
                </div>
              </div>
              <button onClick={() => setShowFlutterSourceModal(false)} className="p-1 text-neutral-400 hover:text-white">
                <X size={18} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto space-y-6 flex-1 text-xs font-mono">
              <div className={`p-4 rounded-xl border ${isDarkMode ? 'bg-[#181818] border-neutral-800' : 'bg-neutral-50 border-neutral-200'}`}>
                <div className="text-xs font-bold font-sans text-neutral-300 mb-2">How to run & build as Native Android APK:</div>
                <div className="space-y-1 text-neutral-400 font-mono text-[11px]">
                  <p># 1. Clone repository or copy /lib, pubspec.yaml, and /android</p>
                  <p className="text-white bg-neutral-900 px-2 py-1 rounded">flutter pub get</p>
                  <p># 2. Run directly in connected Android Device or Emulator:</p>
                  <p className="text-white bg-neutral-900 px-2 py-1 rounded">flutter run</p>
                  <p># 3. Build Production APK:</p>
                  <p className="text-white bg-neutral-900 px-2 py-1 rounded">flutter build apk --release</p>
                </div>
              </div>

              <div>
                <h4 className="font-sans font-bold text-xs uppercase tracking-wider text-neutral-400 mb-2">Flutter & Firebase Architecture:</h4>
                <pre className="p-4 rounded-xl bg-black text-neutral-300 overflow-x-auto text-[11px] leading-relaxed">
{`lib/
├── main.dart                          [Firebase.initializeApp & SystemChrome overlay]
├── app.dart                           [MaterialApp & Theme switching]
├── firebase_options.dart              [FlutterFire config for Android, Web & iOS]
├── theme/
│   └── app_theme.dart                 [Monochrome minimal premium Material 3]
├── models/
│   ├── student.dart                   [Student profile model with fromMap/toMap]
│   ├── course.dart                    [Course catalog model with fromMap/toMap]
│   ├── section.dart                   [Section, instructor, seat model with fromMap/toMap]
│   ├── instructor.dart                [Instructor profile model with fromMap/toMap]
│   ├── registration.dart              [Course registration model with fromMap/toMap]
│   ├── academic_record.dart           [Semester GPA, CGPA & grade history]
│   ├── system_settings.dart           [Registration deadlines & credit limits]
│   └── timetable_entry.dart           [Timetable slot model]
├── services/
│   ├── auth_service.dart              [Firebase Authentication, signIn, register, reset]
│   ├── firestore_service.dart         [Cloud Firestore CRUD, courses, transactions, seed]
│   └── local_data_service.dart        [Rule Engine with Firestore real-time synchronization]
├── widgets/
│   ├── course_card.dart               [Course card with prereq indicators]
│   ├── section_card.dart              [Section card with seat info & conflict badge]
│   ├── timetable_card.dart            [Timetable time-slot card]
│   ├── credit_progress_card.dart      [Interactive credit hours progress bar]
│   ├── registration_status_card.dart  [Open/closed status card with deadline]
│   └── custom_button.dart             [Monochrome button component]
├── screens/
│   ├── auth/
│   │   ├── welcome_screen.dart        [CUI logo, login & demo student bypass]
│   │   ├── login_screen.dart          [Firebase Auth email/password login]
│   │   ├── register_screen.dart       [New student signup & Firestore profile creation]
│   │   └── forgot_password_screen.dart[Firebase sendPasswordResetEmail flow]
│   ├── home/
│   │   └── home_screen.dart           [Live Firestore dashboard & 5-tab NavigationBar]
│   ├── registration/
│   │   ├── course_registration_screen.dart [Course catalog, search, filters]
│   │   ├── course_details_screen.dart      [Syllabus, prereqs, description]
│   │   ├── section_selection_screen.dart   [Section picker, conflict validator]
│   │   └── registered_courses_screen.dart  [Drop course, change section]
│   ├── timetable/
│   │   └── timetable_screen.dart      [Day view & week view class schedules]
│   ├── academic/
│   │   ├── academic_record_screen.dart[CGPA, completed CH, standing]
│   │   └── semester_details_screen.dart[Semester course breakdown & grades]
│   └── profile/
│       ├── profile_screen.dart        [Live student info, settings, Firebase signOut]
│       ├── edit_profile_screen.dart   [Update phone & name]
│       └── settings_screen.dart       [Preferences, support, legal]
pubspec.yaml                           [Flutter 3, firebase_core, firebase_auth, cloud_firestore]
firestore.rules                        [ABAC hardened Zero-Trust Firestore security rules]
firebase-blueprint.json                [Intermediate data models & collections blueprint]
android/
├── app/google-services.json           [Official Firebase Android credentials]
├── app/build.gradle                   [Gradle android config, namespace pk.edu.comsats.portal]
└── app/src/main/AndroidManifest.xml   [Android app manifest]`}</pre>
              </div>
            </div>

            <div className="px-6 py-4 border-t border-neutral-800/60 flex justify-end">
              <button
                onClick={() => setShowFlutterSourceModal(false)}
                className={`px-4 py-2 rounded-xl text-xs font-semibold ${
                  isDarkMode ? 'bg-white text-black' : 'bg-black text-white'
                }`}
              >
                Close Inspector
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
