import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isFullWidth;
  final Widget? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.black : Colors.white),
              ),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: isOutlined
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.black : Colors.white),
                ),
              ),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? Colors.white : Colors.black,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: child,
          );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
