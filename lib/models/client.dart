import 'dart:convert';

class Client {
  final String id;
  String name;
  String contactNumber;
  String address;
  String? profileImagePath;
  List<String> transactionIds;
  DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.address,
    this.profileImagePath,
    List<String>? transactionIds,
    DateTime? createdAt,
  })  : transactionIds = transactionIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactNumber': contactNumber,
        'address': address,
        'profileImagePath': profileImagePath,
        'transactionIds': transactionIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'],
        name: json['name'],
        contactNumber: json['contactNumber'],
        address: json['address'],
        profileImagePath: json['profileImagePath'],
        transactionIds: List<String>.from(json['transactionIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
      );

  Client copyWith({
    String? name,
    String? contactNumber,
    String? address,
    String? profileImagePath,
    List<String>? transactionIds,
  }) =>
      Client(
        id: id,
        name: name ?? this.name,
        contactNumber: contactNumber ?? this.contactNumber,
        address: address ?? this.address,
        profileImagePath: profileImagePath ?? this.profileImagePath,
        transactionIds: transactionIds ?? this.transactionIds,
        createdAt: createdAt,
      );
}