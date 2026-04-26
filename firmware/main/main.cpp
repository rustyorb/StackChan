/*
 * SPDX-FileCopyrightText: 2026 M5Stack Technology CO LTD
 *
 * SPDX-License-Identifier: MIT
 */
#include <smooth_ui_toolkit.hpp>
#include <uitk/short_namespace.hpp>
#include <mooncake_log.h>
#include <mooncake.h>
#include <apps/apps.h>
#include <hal/hal.h>
#include <esp_app_desc.h>
#include <esp_log.h>

using namespace mooncake;
using namespace smooth_ui_toolkit;

extern "C" void app_main(void)
{
    const auto* app_desc = esp_app_get_description();
    ESP_LOGW("StackChanFork", "Booting StackChan fork firmware %s built %s %s", app_desc->version,
             app_desc->date, app_desc->time);

    // Setup logger
    mclog::set_level(mclog::level_info);
    mclog::set_time_format(mclog::time_format_unix_milliseconds);

    // HAL init
    GetHAL().init();

    // Setup ui hal
    ui_hal::on_delay([](uint32_t ms) { GetHAL().delay(ms); });
    ui_hal::on_get_tick([]() { return GetHAL().millis(); });

    // Install apps
    GetMooncake().installApp(std::make_unique<AppLauncher>());
    GetMooncake().installApp(std::make_unique<AppAiAgent>());
    GetMooncake().installApp(std::make_unique<AppAvatar>());
    GetMooncake().installApp(std::make_unique<AppEspnowControl>());
    GetMooncake().installApp(std::make_unique<AppAppCenter>());
    GetMooncake().installApp(std::make_unique<AppEzdata>());
    GetMooncake().installApp(std::make_unique<AppDance>());
    GetMooncake().installApp(std::make_unique<AppSetup>());

    // Main loop
#if STACKCHAN_DEV_FIRMWARE
    const auto xiaozhi_auto_start_at = GetHAL().millis() + 8000;
    bool xiaozhi_auto_start_requested = false;
#endif
    while (1) {
        GetHAL().feedTheDog();
        GetHAL().updateHeapStatusLog();

        GetMooncake().update();

#if STACKCHAN_DEV_FIRMWARE
        if (!xiaozhi_auto_start_requested && GetHAL().millis() >= xiaozhi_auto_start_at) {
            xiaozhi_auto_start_requested = true;
            ESP_LOGW("StackChanFork", "Dev firmware auto-starting XiaoZhi voice mode");
            GetHAL().requestXiaozhiStart();
        }
#endif

        if (GetHAL().isXiaozhiStartRequested()) {
            break;
        }
    }

    // Uninstall all apps and destroy mooncake
    GetMooncake().uninstallAllApps();
    DestroyMooncake();

    // Start xiaozhi, never returns
    GetHAL().startXiaozhi();
}
