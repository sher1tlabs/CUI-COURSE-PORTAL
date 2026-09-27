export interface Student {
  id: string;
  name: string;
  registrationNumber: string;
  email: string;
  phoneNumber: string;
  program: string;
  campus: string;
  batch: string;
  semester: number;
  cgpa: number;
  completedCreditHours: number;
  academicStanding: string;
  avatarUrl?: string;
}

export interface Course {
  code: string;
  title: string;
  creditHours: number;
  department: string;
  description: string;
  prerequisites: string[];
  corequisites: string[];
  courseType: 'Core' | 'Elective' | 'University Requirement';
  recommendedSemester: number;
}

export interface Section {
  id: string;
  courseCode: string;
  sectionName: string;
  instructor: string;
  instructorId: string;
  days: string[];
  startTime: string;
  endTime: string;
  room: string;
  totalSeats: number;
  availableSeats: number;
}

export interface Registration {
  id: string;
  studentId: string;
  courseCode: string;
  sectionId: string;
  semester: string;
  status: 'Registered' | 'Pending' | 'Dropped';
  registrationDate: string;
}

export interface TimetableEntry {
  id: string;
  courseCode: string;
  courseTitle: string;
  sectionName: string;
  instructor: string;
  day: string;
  startTime: string;
  endTime: string;
  room: string;
  creditHours: number;
}

export interface Instructor {
  id: string;
  name: string;
  designation: string;
  department: string;
  coursesTaught: string[];
  office: string;
  email: string;
  phone: string;
}

export interface NotificationItem {
  id: string;
  title: string;
  message: string;
  time: string;
  isRead: boolean;
}

export interface SemesterHistoryItem {
  semester: string;
  gpa: number;
  creditHours: number;
  courses: Array<{
    code: string;
    title: string;
    ch: number;
    grade: string;
  }>;
}
