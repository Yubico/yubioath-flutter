#include "flutter_window.h"

#include <optional>

#include <UIAutomationCore.h>
#include <UIAutomationCoreApi.h>
#include <UIAutomationClient.h>
#include <oleauto.h>

#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

namespace {

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }

  const int size_needed =
      MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                          nullptr, 0);
  if (size_needed <= 0) {
    return std::wstring();
  }

  std::wstring wstr(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      wstr.data(), size_needed);
  return wstr;
}

HWND CreateHiddenAnnouncementWindow(HWND parent) {
  // A tiny static control, kept visible for accessibility clients.
  return CreateWindowExW(0, L"STATIC", L"",
                         WS_CHILD | WS_VISIBLE, 0, 0, 1, 1, parent,
                         nullptr, GetModuleHandle(nullptr), nullptr);
}

void RaiseUiaNotification(HWND hwnd, HWND announce_hwnd,
                          const std::wstring& message) {
  if (message.empty()) {
    return;
  }

  if (announce_hwnd != nullptr) {
    SetWindowTextW(announce_hwnd, message.c_str());
    NotifyWinEvent(EVENT_OBJECT_NAMECHANGE, announce_hwnd, OBJID_CLIENT,
                   CHILDID_SELF);
    NotifyWinEvent(EVENT_OBJECT_LIVEREGIONCHANGED, announce_hwnd, OBJID_CLIENT,
                   CHILDID_SELF);
  }

  IRawElementProviderSimple* provider = nullptr;
  const HWND provider_hwnd = announce_hwnd != nullptr ? announce_hwnd : hwnd;
  if (FAILED(UiaHostProviderFromHwnd(provider_hwnd, &provider)) ||
      provider == nullptr) {
    return;
  }

  BSTR display_string = SysAllocString(message.c_str());
  // Must not be null per API contract.
  if (display_string == nullptr) {
    provider->Release();
    return;
  }

  // Some ATs read the activity id instead of (or before) the display string.
  // Use the message for both so that the spoken text is predictable.
  BSTR activity_id = SysAllocString(message.c_str());
  if (activity_id == nullptr) {
    SysFreeString(display_string);
    provider->Release();
    return;
  }

  UiaRaiseNotificationEvent(provider, NotificationKind_ActionCompleted,
                            NotificationProcessing_ImportantMostRecent,
                            display_string, activity_id);
  // Some ATs may not yet honor notification events, but do honor the live
  // region changed event.
  UiaRaiseAutomationEvent(provider, UIA_LiveRegionChangedEventId);

  SysFreeString(display_string);
  SysFreeString(activity_id);
  provider->Release();
}

}  // namespace

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  if (a11y_announce_hwnd_ == nullptr) {
    a11y_announce_hwnd_ = CreateHiddenAnnouncementWindow(GetHandle());
  }

  a11y_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "yubico_authenticator/a11y",
      &flutter::StandardMethodCodec::GetInstance());
  a11y_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("announce") != 0) {
          result->NotImplemented();
          return;
        }

        std::string message;
        if (call.arguments() != nullptr) {
          if (std::holds_alternative<std::string>(*call.arguments())) {
            message = std::get<std::string>(*call.arguments());
          } else if (std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
            const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
            const auto message_it =
                args.find(flutter::EncodableValue("message"));
            if (message_it != args.end() &&
                std::holds_alternative<std::string>(message_it->second)) {
              message = std::get<std::string>(message_it->second);
            }
          }
        }

        RaiseUiaNotification(GetHandle(), a11y_announce_hwnd_,
                             Utf8ToWide(message));
        result->Success();
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  if (a11y_announce_hwnd_ != nullptr) {
    DestroyWindow(a11y_announce_hwnd_);
    a11y_announce_hwnd_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
