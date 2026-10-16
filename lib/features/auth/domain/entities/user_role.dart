/// Entity UserRole merepresentasikan peran dalam rumah tangga
enum UserRole {
  husband('Suami', '👨', 'Mengatur nafkah, agenda, & tugas keluarga'),
  wife('Istri', '👩', 'Mengatur menu makan, budget harian, & belanja');

  final String label;
  final String iconEmoji;
  final String description;

  const UserRole(this.label, this.iconEmoji, this.description);

  bool get isHusband => this == UserRole.husband;
  bool get isWife => this == UserRole.wife;
}
