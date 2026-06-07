import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/lesson_model.dart';

void main() {
  group('LessonModel', () {
    test('kAllLessons has exactly 12 lessons', () {
      expect(kAllLessons.length, 12);
    });

    test('all lessons have non-empty fields', () {
      for (final lesson in kAllLessons) {
        expect(lesson.id, isNotEmpty, reason: 'Lesson ${lesson.title} missing id');
        expect(lesson.title, isNotEmpty, reason: 'Lesson ${lesson.id} missing title');
        expect(lesson.description, isNotEmpty, reason: 'Lesson ${lesson.id} missing description');
        expect(lesson.category, isNotEmpty, reason: 'Lesson ${lesson.id} missing category');
        expect(lesson.steps, isNotEmpty, reason: 'Lesson ${lesson.id} has no steps');
      }
    });

    test('all lessons have valid categories', () {
      const valid = {'privacy', 'passwords', 'networks'};
      for (final lesson in kAllLessons) {
        expect(valid.contains(lesson.category), isTrue,
            reason: 'Lesson ${lesson.id} has invalid category: ${lesson.category}');
      }
    });

    test('every lesson has at least 3 steps', () {
      for (final lesson in kAllLessons) {
        expect(lesson.steps.length, greaterThanOrEqualTo(3),
            reason: 'Lesson ${lesson.id} has fewer than 3 steps');
      }
    });

    test('no duplicate lesson IDs', () {
      final ids = kAllLessons.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'Duplicate lesson IDs found');
    });
  });
}
