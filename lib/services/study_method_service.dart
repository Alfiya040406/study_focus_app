import '../models/study_method.dart';

class StudyMethodService {
  static List<StudyMethod> getStudyMethods() {
    return const [
      StudyMethod(
        title: 'Pomodoro',
        description:
            'Study in short bursts with regular breaks to maintain focus and avoid burnout.',
        focusMinutes: 25,
        breakMinutes: 5,
        revisionMinutes: 10,
        videoUrl: 'https://youtu.be/mNBmG24djoY',
      ),
      StudyMethod(
        title: 'Deep Work',
        description:
            'Long distraction-free sessions for intense concentration and productivity.',
        focusMinutes: 50,
        breakMinutes: 10,
        revisionMinutes: 15,
        videoUrl: 'https://youtu.be/3E7hkPZ-HTk',
      ),
      StudyMethod(
        title: 'Active Recall',
        description:
            'Focus on remembering concepts by testing yourself and revising frequently.',
        focusMinutes: 30,
        breakMinutes: 5,
        revisionMinutes: 20,
        videoUrl: 'https://youtu.be/fDbxPVn02VU',
      ),
      StudyMethod(
        title: 'Blurting Method',
        description:
            'Study a topic, then write everything you remember to strengthen memory.',
        focusMinutes: 35,
        breakMinutes: 7,
        revisionMinutes: 15,
        videoUrl: 'https://youtu.be/W3pUC9g8U1U',
      ),
      StudyMethod(
        title: '90-Min Flow',
        description:
            'Deep focus session aligned with the brain’s natural ultradian rhythm.',
        focusMinutes: 90,
        breakMinutes: 20,
        revisionMinutes: 20,
        videoUrl: 'https://youtu.be/aXvDEmo6uS4',
      ),
    ];
  }
}
