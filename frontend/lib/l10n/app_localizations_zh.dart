// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '她绝对是故意的';

  @override
  String get splashTitle => '她绝对是故意的';

  @override
  String get splashBubbleText =>
      '你的暧昧对象刚做了一件让你抓狂的事，你需要立刻吐槽。Jess随时待命。一个AI闺蜜，永远在线，永远投入，真心实意地在电话旁等着你。好问题。零评判。官方评级。她第一声就接了。开始聊吧。';

  @override
  String get privacyTitle => '🔒 你的隐私很重要';

  @override
  String get privacyText =>
      '所有对话只存储在你的设备本地。没有账户。没有云存储。没有数据收集。当你删除应用程序时，一切都会随之消失。';

  @override
  String get githubButton => '在GitHub上查看';

  @override
  String get createdByText => '由独立女同性恋开发者Janet Jeffus创建。\n了解更多：';

  @override
  String get getStartedButton => '开始';

  @override
  String get chatScreenTitle => '汇报情况';

  @override
  String get chatScreenHintText => '有什么瓜，说来听听...';

  @override
  String get chatScreenWelcomeMessage => '嘿，闺蜜！很高兴你来了。在想什么呢？';

  @override
  String get chatScreenErrorUnexpected => '发生了意外错误。请再试一次。';

  @override
  String get chatScreenErrorRetryInProgress => '请稍等，处理时间比平时长一些';

  @override
  String get chatScreenErrorJessProblem => 'Jess现在有点问题。';

  @override
  String get emptyStateTitle => '还没有任何汇报。';

  @override
  String get emptyStateSubtitle => '你还在等什么？';

  @override
  String get emptyStateButton => '开始汇报';
}
