// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
//
// laptime-idle: tells Lap Time how long you've been away from the keyboard and mouse.
//
// Uses the Wayland ext-idle-notify-v1 "input idle" notification (version 2), which only
// looks at real keyboard, mouse and touch input. Video or music that keeps the screen
// awake does not count as activity. State is written to $XDG_RUNTIME_DIR/laptime-idle:
//   "active"           you are using the computer
//   "idle <epoch_ms>"  no input since <epoch_ms>
// Usage: laptime-idle [timeout_seconds]   (default 60)

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>
#include "ext-idle-notify-v1-client-protocol.h"

static struct wl_seat *seat;
static struct ext_idle_notifier_v1 *notifier;
static uint32_t notifier_version;
static uint32_t timeout_ms = 60000;
static char state_path[4096];
static char tmp_path[4096 + 8];

static long long now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static void write_state(const char *text)
{
    FILE *f = fopen(tmp_path, "w");
    if (!f) {
        fprintf(stderr, "laptime-idle: cannot write %s: %s\n", tmp_path, strerror(errno));
        return;
    }
    fprintf(f, "%s\n", text);
    fclose(f);
    rename(tmp_path, state_path);
}

static void on_idled(void *data, struct ext_idle_notification_v1 *n)
{
    (void)data; (void)n;
    char buf[64];
    snprintf(buf, sizeof buf, "idle %lld", now_ms() - timeout_ms);
    write_state(buf);
}

static void on_resumed(void *data, struct ext_idle_notification_v1 *n)
{
    (void)data; (void)n;
    write_state("active");
}

static const struct ext_idle_notification_v1_listener notification_listener = {
    .idled = on_idled,
    .resumed = on_resumed,
};

static void on_global(void *data, struct wl_registry *reg, uint32_t name, const char *iface, uint32_t version)
{
    (void)data;
    if (!seat && strcmp(iface, wl_seat_interface.name) == 0) {
        seat = wl_registry_bind(reg, name, &wl_seat_interface, 1);
    } else if (strcmp(iface, ext_idle_notifier_v1_interface.name) == 0) {
        notifier_version = version < 2 ? version : 2;
        notifier = wl_registry_bind(reg, name, &ext_idle_notifier_v1_interface, notifier_version);
    }
}

static void on_global_remove(void *data, struct wl_registry *reg, uint32_t name)
{
    (void)data; (void)reg; (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = on_global,
    .global_remove = on_global_remove,
};

static void on_signal(int sig)
{
    (void)sig;
    unlink(state_path);
    _exit(0);
}

int main(int argc, char **argv)
{
    if (argc > 1) {
        long secs = strtol(argv[1], NULL, 10);
        if (secs < 5 || secs > 3600) {
            fprintf(stderr, "usage: %s [timeout_seconds 5-3600]\n", argv[0]);
            return 2;
        }
        timeout_ms = (uint32_t)secs * 1000;
    }

    const char *runtime = getenv("XDG_RUNTIME_DIR");
    if (!runtime || !*runtime) {
        fprintf(stderr, "laptime-idle: XDG_RUNTIME_DIR is not set\n");
        return 1;
    }
    snprintf(state_path, sizeof state_path, "%s/laptime-idle", runtime);
    snprintf(tmp_path, sizeof tmp_path, "%s.tmp", state_path);

    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "laptime-idle: no Wayland session\n");
        return 1;
    }
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip(display);

    if (!seat || !notifier) {
        fprintf(stderr, "laptime-idle: compositor has no idle notifier\n");
        return 1;
    }

    struct ext_idle_notification_v1 *n;
    if (notifier_version >= 2) {
        n = ext_idle_notifier_v1_get_input_idle_notification(notifier, timeout_ms, seat);
    } else {
        // Older compositors: media that keeps the screen awake will also count as activity.
        fprintf(stderr, "laptime-idle: input-only idle not supported, using screen idle\n");
        n = ext_idle_notifier_v1_get_idle_notification(notifier, timeout_ms, seat);
    }
    ext_idle_notification_v1_add_listener(n, &notification_listener, NULL);

    signal(SIGTERM, on_signal);
    signal(SIGINT, on_signal);
    write_state("active");

    while (wl_display_dispatch(display) != -1) {
    }
    unlink(state_path);
    fprintf(stderr, "laptime-idle: Wayland connection closed\n");
    return 1;
}
