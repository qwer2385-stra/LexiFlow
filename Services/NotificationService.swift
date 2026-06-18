import UserNotifications
import UIKit

/// 推送通知服务
final class NotificationService {

    // MARK: - 请求权限

    /// 请求通知权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("通知权限请求失败: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }

    // MARK: - 定时提醒

    /// 设置每日学习提醒
    func scheduleDailyReminder(hour: Int, minute: Int) {
        // 先取消已有提醒
        cancelAllNotifications()

        let content = UNMutableNotificationContent()
        content.title = "LexiFlow — 学习时间到！📚"
        content.body = "每天进步一点点，今天的学习任务正在等你完成。"
        content.sound = .default
        content.categoryIdentifier = AppConstants.notificationCategoryIdentifier

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: AppConstants.notificationCategoryIdentifier,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 取消通知

    /// 取消所有待发送的通知
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - 检查权限状态

    /// 异步获取当前通知权限状态
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
}
