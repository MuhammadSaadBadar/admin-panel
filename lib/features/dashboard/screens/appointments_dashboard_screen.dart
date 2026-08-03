import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/route_names.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedTab = 'upcoming';

  final List<Appointment> _appointments = [
    Appointment(
      id: 'APT-001',
      patientName: 'Sarah Jenkins',
      patientImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBCfhrGtu-yQLJihqua-iKuoQyy_SwNSSrKA-H177LTrm3nDLriKKsZ5cVqD5d5eXmGwDlF25371OM_WH4Wki-kmlQW_abwLp8PyV8WaJdCLW8Xnl5uMbbIUHzyrmUS5dpufD3e70HcnWHftYxr4vrsoYUnoHY1YBP2hASC1GJthwEpOARGMHTmK2bNtPvXqaNBwzhj9-lk52D92dwi4PbMO_Dq5ihR8QiDwwsNh-RX7AEerdcOHJ9k',
      appointmentType: 'Ultrasound • Routine Scan',
      doctor: 'Dr. Elena Rodriguez',
      date: 'Oct 24',
      time: '09:15 AM',
      status: AppointmentStatus.upcoming,
    ),
    Appointment(
      id: 'APT-002',
      patientName: 'Monica Geller',
      patientImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBiLti0f7SCzrpqddgnkhnc0boUhfOGceyZ5HVfctUHdgvuSpbI4R1zKzKGeR0SvePlRpZ7rRaEjcUnI5SUemfPfDRLb-uhYzlUDHZPsoXOr7I0eRmA4jXYcDc3eYWssLPWgvkH6LTuUvtpMV0vuLX7NZc6eoT_iK77R9po-yeiSmeh0Q1jl5Pk4eGxqhoLylP6LU6iCECcUlFWmWyJ-APegXj8fCwqUmMheeVsi768uc-ZL_hHA37E',
      appointmentType: 'Checkup • Post-natal Visit',
      doctor: 'Dr. Simon Baker',
      date: 'Oct 24',
      time: '11:30 AM',
      status: AppointmentStatus.upcoming,
    ),
    Appointment(
      id: 'APT-003',
      patientName: 'Aisha Khan',
      patientImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCtH6pY-5by8i0WThRPNLK-tPkvNkjxnN2UsGX6UMvCYqLpWSZoPGoQXyjFYhEyLQrDQ-j-73nE5y6_WqPf-Pd9PW2uvNv1OJJ3qDgkyE0WY-6sS4zAZGCrrXAOCPG-TgQq0viItIzGlZ9GkwurPpFfpr6fEeqKf8FF8NsHFum5T8TkEuMbg2mW3lHQwxnzudbSQTk1d9zDjk45u_FgS-xhSfW7DmYiwspX19a3hUoM_obCyibBH3Jy',
      appointmentType: 'Genetic Testing • Consultation',
      doctor: 'Dr. Elena Rodriguez',
      date: 'Oct 25',
      time: '08:00 AM',
      status: AppointmentStatus.upcoming,
    ),
    Appointment(
      id: 'APT-004',
      patientName: 'Chloe Price',
      patientImage:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBB4bZ_EKB6UJJnzBzl5CxkOpgcM7kSzcRbwL8AuBcmbpLWgtrlckeEV0XCNYuFG8X__GK3WJY5zy5jFJXduTINbc8NFQQDB60gWiuXPYo_qmoJPSJp5XINnti4eRPP6Cos8NfEUPEyDtE_0UFk5x2QsE0e5hCPTngroE4XruP0GpyfYWAaU5fEc4CSl-sMc628mTrleoSD2W9zz1aDsyzFaaQe1SDeY_CFC179XXTHOXX87DiYR_6P',
      appointmentType: 'Blood Work • Screening',
      doctor: 'Dr. Simon Baker',
      date: 'Oct 25',
      time: '01:45 PM',
      status: AppointmentStatus.upcoming,
    ),
  ];

  List<Appointment> get _filteredAppointments {
    return _appointments.where((app) {
      switch (_selectedTab) {
        case 'upcoming':
          return app.status == AppointmentStatus.upcoming;
        case 'completed':
          return app.status == AppointmentStatus.completed;
        case 'cancelled':
          return app.status == AppointmentStatus.cancelled;
        default:
          return true;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildTabs(isMobile),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildAppointmentList(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? AppBottomNavBar(
              selectedIndex: 3,
              onItemSelected: (index) {
                switch (index) {
                  case 0:
                    Get.toNamed(RouteNames.dashboard);
                    break;
                  case 1:
                    Get.toNamed(RouteNames.doctors);
                    break;
                  case 2:
                    Get.toNamed(RouteNames.patients);
                    break;
                  case 3:
                    break;
                }
              },
            )
          : null,
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: ColorConstants.appBarBackground,
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: ColorConstants.primary,
                    size: 20,
                  ),
                ),
              Text(
                'Appointments',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications,
                  color: ColorConstants.primary,
                  size: isMobile ? 20 : 24,
                ),
              ),
              if (isMobile)
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.menu,
                    color: ColorConstants.primary,
                    size: 20,
                  ),
                ),
              if (!isMobile)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorConstants.primary.withOpacity(0.2),
                    ),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuB1NKpvAup4gqFgvKjBARtyHXD_jecyXH1PhwY6a9ARwVkfY0Jp9hxrIQDLdK82mzng-Rts_w8J7elf9AnJlOgS-Fjebi-Ul_n1jjvK-2pjwAUtEpqOnb7m8ZX3x2BJgbuiA8tMjfmUHZ46IJSgZSxqca4mJuXFkcZfFgIENc1g4L6Uq4oim-ol0i4PSfrtCmarC3yGsL8ZNV3AWeXPUf7h1exErubCfhoh4e7Ek4tmMMiWIRDu9muY',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Management',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          'Review, filter, and manage upcoming patient appointments.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w400,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isMobile) {
    final tabs = [
      {'id': 'upcoming', 'label': 'Upcoming'},
      {'id': 'completed', 'label': 'Completed'},
      {'id': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ColorConstants.borderWhite10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _selectedTab == tab['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab['id']!;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                  horizontal: 4,
                ),
                margin: EdgeInsets.only(right: isMobile ? 20 : 32),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? ColorConstants.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab['label']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: isSelected
                        ? ColorConstants.primary
                        : ColorConstants.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(bool isMobile) {
    if (_filteredAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 48),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                color: ColorConstants.onSurfaceVariant,
                size: isMobile ? 40 : 48,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'No appointments found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _filteredAppointments.map((appointment) {
        return _buildAppointmentItem(appointment, isMobile);
      }).toList(),
    );
  }

  Widget _buildAppointmentItem(Appointment appointment, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        children: [
          // Patient Info Row
          Row(
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              // Patient Avatar
              Stack(
                children: [
                  Container(
                    width: isMobile ? 40 : 48,
                    height: isMobile ? 40 : 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorConstants.onSurfaceVariant,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(appointment.patientImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: isMobile ? 10 : 12,
                      height: isMobile ? 10 : 12,
                      decoration: BoxDecoration(
                        color: ColorConstants.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorConstants.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: isMobile ? 12 : 16),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onSurface,
                      ),
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      appointment.appointmentType,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Appointment ID
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: isMobile ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  appointment.id,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Divider(height: 1, color: ColorConstants.borderWhite5),
          SizedBox(height: isMobile ? 12 : 16),
          // Appointment Details
          if (isMobile)
            Column(
              children: [
                _buildDetailRow(
                  'Practitioner',
                  appointment.doctor,
                  Icons.medical_services,
                  isMobile,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Date & Time',
                  '${appointment.date}, ${appointment.time}',
                  Icons.event,
                  isMobile,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    'Practitioner',
                    appointment.doctor,
                    Icons.medical_services,
                    false,
                  ),
                ),
                Expanded(
                  child: _buildDetailRow(
                    'Date & Time',
                    '${appointment.date}, ${appointment.time}',
                    Icons.event,
                    false,
                  ),
                ),
              ],
            ),
          SizedBox(height: isMobile ? 12 : 16),
          Divider(height: 1, color: ColorConstants.borderWhite5),
          SizedBox(height: isMobile ? 12 : 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstants.onSurfaceVariant,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: ColorConstants.borderWhite10),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryContainer,
                    foregroundColor: ColorConstants.onPrimaryContainer,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    shadowColor: ColorConstants.primary.withOpacity(0.05),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: ColorConstants.primary, size: isMobile ? 16 : 18),
            SizedBox(width: isMobile ? 4 : 6),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: ColorConstants.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Data Models
enum AppointmentStatus { upcoming, completed, cancelled }

class Appointment {
  final String id;
  final String patientName;
  final String patientImage;
  final String appointmentType;
  final String doctor;
  final String date;
  final String time;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.patientName,
    required this.patientImage,
    required this.appointmentType,
    required this.doctor,
    required this.date,
    required this.time,
    required this.status,
  });
}
