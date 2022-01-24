class User {
  int uid; //reference to user uid

  bool isSpeaking;
  // String name; // reference to whether the user is speaking

  User(
    this.uid,
    this.isSpeaking,
    //  this.name
  );

  @override
  String toString() {
    return 'User{uid: $uid, isSpeaking: $isSpeaking}';
  }
}
