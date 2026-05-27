// lib/features/members/utils/relationship_mapper.dart

class RelationshipMapper {
  static String getDisplayName(String relationshipId) {
    switch (relationshipId) {
      case "me":
        return "Me";
      case "spouse":
        return "Spouse";
      case "father":
        return "Father";
      case "mother":
        return "Mother";
      case "son":
        return "Son";
      case "daughter":
        return "Daughter";
      case "brother":
        return "Brother";
      case "sister":
        return "Sister";
      default:
        return relationshipId;
    }
  }
}
