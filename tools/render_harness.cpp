// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Universal offscreen QML render harness supporting QQuickItem and QQuickWindow.

#include <QGuiApplication>
#include <QQuickView>
#include <QQuickWindow>
#include <QQuickItem>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlError>
#include <QImage>
#include <QThread>
#include <iostream>
#include <cstdlib>

int main(int argc, char **argv) {
    if (argc < 3) {
        std::cerr << "Usage: render_harness <qml_file> <output_png> [width] [height]" << std::endl;
        return 1;
    }

    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    qputenv("PULSE_SERVER", "/dev/null");
    qputenv("PULSE_AUTOSPAWN", "0");
    qputenv("CANBERRA_DRIVER", "null");

    int width = (argc > 3) ? std::atoi(argv[3]) : 2560;
    int height = (argc > 4) ? std::atoi(argv[4]) : 1600;

    QGuiApplication app(argc, argv);

    QQmlEngine engine;
    engine.addImportPath("/usr/lib/x86_64-linux-gnu/qt6/qml");

    QQmlComponent comp(&engine, QUrl::fromLocalFile(argv[1]));
    if (comp.isError()) {
        for (const auto &err : comp.errors()) {
            std::cerr << "QML Error: " << err.toString().toStdString() << std::endl;
        }
        return 1;
    }

    QObject *obj = comp.create();
    if (!obj) {
        for (const auto &err : comp.errors()) {
            std::cerr << "QML Create Error: " << err.toString().toStdString() << std::endl;
        }
        return 1;
    }

    QQuickWindow *win = qobject_cast<QQuickWindow*>(obj);
    QQuickView *view = nullptr;
    if (!win) {
        QQuickItem *item = qobject_cast<QQuickItem*>(obj);
        if (item) {
            view = new QQuickView(&engine, nullptr);
            view->setResizeMode(QQuickView::SizeRootObjectToView);
            view->resize(width, height);
            item->setParentItem(view->contentItem());
            item->setWidth(width);
            item->setHeight(height);
            win = view;
        }
    } else {
        win->resize(width, height);
    }

    if (!win) {
        std::cerr << "Root object is neither QQuickWindow nor QQuickItem." << std::endl;
        return 1;
    }

    win->show();

    // Settle layouts, bindings, textures and event loops
    for (int i = 0; i < 25; ++i) {
        QCoreApplication::processEvents();
        QThread::msleep(20);
    }

    QImage img = win->grabWindow();
    if (!img.isNull()) {
        if (!img.save(argv[2])) {
            std::cerr << "Failed to save render to: " << argv[2] << std::endl;
            return 1;
        }
        std::cout << "Successfully rendered: " << argv[2] << " (" << img.width() << "x" << img.height() << ")" << std::endl;
        return 0;
    } else {
        std::cerr << "Failed to grab window image." << std::endl;
        return 1;
    }
}
