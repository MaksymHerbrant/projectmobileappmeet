class RegistrationModel {
  String? phoneNumber;
  String? smsCode;
  String? email;
  String? password;
  String? confirmPassword;
  String? name;
  
  // Кроки реєстрації
  static const int totalSteps = 5;
  
  // Метод для очищення даних
  void clearData() {
    phoneNumber = null;
    smsCode = null;
    email = null;
    password = null;
    confirmPassword = null;
    name = null;
  }
  
  // Метод для очищення даних з поточного кроку
  void clearCurrentStepData(int step) {
    switch (step) {
      case 1:
        phoneNumber = null;
        break;
      case 2:
        smsCode = null;
        break;
      case 3:
        email = null;
        break;
      case 4:
        password = null;
        confirmPassword = null;
        break;
      case 5:
        name = null;
        break;
    }
  }
  
  // Валідація для кожного кроку
  bool isStep1Valid() {
    return phoneNumber != null && 
           phoneNumber!.trim().isNotEmpty && 
           phoneNumber!.length >= 9; // 9 цифр для українського номера без коду країни
  }
  
  bool isStep2Valid() {
    return smsCode != null && 
           smsCode!.trim().isNotEmpty && 
           smsCode!.length == 6;
  }
  
  bool isStep3Valid() {
    return email != null && 
           email!.trim().isNotEmpty &&
           email!.contains('@') && 
           email!.contains('.');
  }
  
  bool isStep4Valid() {
    return password != null && 
           password!.trim().isNotEmpty &&
           confirmPassword != null &&
           confirmPassword!.trim().isNotEmpty &&
           password!.length >= 8 &&
           password == confirmPassword;
  }
  
  bool isStep5Valid() {
    return name != null && 
           name!.trim().isNotEmpty;
  }
  
  bool isRegistrationComplete() {
    return isStep1Valid() && 
           isStep2Valid() && 
           isStep3Valid() && 
           isStep4Valid() && 
           isStep5Valid();
  }
} 