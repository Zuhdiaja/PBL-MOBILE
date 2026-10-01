class DemoAccount {
  DemoAccount._();

  static const name = 'Nadia Putri';
  static const email = 'nadia@gmail.com';
  static const password = '123456';

  static bool matches(String emailInput, String passwordInput) =>
      emailInput.trim().toLowerCase() == email && passwordInput == password;
}
