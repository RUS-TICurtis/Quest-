enum OpportunityType { job, internship, volunteer, research, mentorship }

class Opportunity {
  final String id;
  final String providerId; // Org or User ID
  final String title;
  final String description;
  final OpportunityType type;
  final String location; // e.g., 'Remote', 'Campus', 'San Francisco'
  final bool isPaid;
  final double? compensationAmount;
  final DateTime createdAt;
  final DateTime expiresAt;

  Opportunity({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    this.isPaid = false,
    this.compensationAmount,
    required this.createdAt,
    required this.expiresAt,
  });
}
