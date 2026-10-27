class DriverProfile {
  final String id;
  final String name;
  final String phone;
  final String licensePlate;
  final String truckType;
  final String companyName;
  bool isClockedIn;
  DateTime? clockInTime;
  int sessionDaysRemaining;
  bool autoRenewActive;

  DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.licensePlate,
    required this.truckType,
    required this.companyName,
    this.isClockedIn = false,
    this.clockInTime,
    this.sessionDaysRemaining = 45,
    this.autoRenewActive = true,
  });

  void clockIn() {
    isClockedIn = true;
    clockInTime = DateTime.now();
  }

  void clockOut() {
    isClockedIn = false;
    clockInTime = null;
  }

  void renewSession() {
    sessionDaysRemaining = 45;
  }
}
