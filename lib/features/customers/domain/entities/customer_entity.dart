/// Domain entity representing a customer.
class CustomerEntity {
  final String id;
  final String organizationId;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? avatarLabel;
  final CustomerTierEntity tier;
  final CustomerStatusEntity status;
  final double totalSpent;
  final int totalVisits;
  final int loyaltyPoints;
  final List<String> tags;
  final String? notes;
  final DateTime? lastVisitAt;
  final DateTime createdAt;

  const CustomerEntity({
    required this.id,
    required this.organizationId,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.avatarLabel,
    required this.tier,
    required this.status,
    required this.totalSpent,
    required this.totalVisits,
    required this.loyaltyPoints,
    this.tags = const [],
    this.notes,
    this.lastVisitAt,
    required this.createdAt,
  });

  CustomerEntity copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    CustomerTierEntity? tier,
    CustomerStatusEntity? status,
    double? totalSpent,
    int? totalVisits,
    int? loyaltyPoints,
    List<String>? tags,
    String? notes,
    DateTime? lastVisitAt,
  }) {
    return CustomerEntity(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLabel: avatarLabel,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      totalSpent: totalSpent ?? this.totalSpent,
      totalVisits: totalVisits ?? this.totalVisits,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CustomerEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum CustomerTierEntity { bronze, silver, gold, vip }

enum CustomerStatusEntity { active, atRisk, inactive, new_ }
