/*
 * SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
 * SPDX-FileCopyrightText: 2014 Hugo Pereira Da Costa <hugo.pereira@free.fr>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */
#include "breezebutton.h"

#include <KColorUtils>
#include <KDecoration3/DecoratedWindow>
#include <KIconLoader>

#include <QPainter>
#include <QPainterPath>
#include <QVariantAnimation>

namespace WindowPerch
{
using KDecoration3::ColorGroup;
using KDecoration3::ColorRole;
using KDecoration3::DecorationButtonType;

//__________________________________________________________________
Button::Button(DecorationButtonType type, Decoration *decoration, QObject *parent)
    : DecorationButton(type, decoration, parent)
    , m_animation(new QVariantAnimation(this))
{
    // setup animation
    // It is important start and end value are of the same type, hence 0.0 and not just 0
    m_animation->setStartValue(0.0);
    m_animation->setEndValue(1.0);
    m_animation->setEasingCurve(QEasingCurve::InOutQuad);
    connect(m_animation, &QVariantAnimation::valueChanged, this, [this](const QVariant &value) {
        setOpacity(value.toReal());
    });

    // connections
    connect(decoration->window(), SIGNAL(iconChanged(QIcon)), this, SLOT(update()));
    connect(decoration->settings().get(), &KDecoration3::DecorationSettings::reconfigured, this, &Button::reconfigure);
    connect(this, &KDecoration3::DecorationButton::hoveredChanged, this, &Button::updateAnimationState);

    reconfigure();
}

//__________________________________________________________________
Button::Button(QObject *parent, const QVariantList &args)
    : Button(args.at(0).value<DecorationButtonType>(), args.at(1).value<Decoration *>(), parent)
{
    setGeometry(QRectF(QPointF(0, 0), preferredSize()));
}

//__________________________________________________________________
Button *Button::create(DecorationButtonType type, KDecoration3::Decoration *decoration, QObject *parent)
{
    if (auto d = qobject_cast<Decoration *>(decoration)) {
        Button *b = new Button(type, d, parent);
        const auto c = d->window();
        switch (type) {
        case DecorationButtonType::Close:
            b->setVisible(c->isCloseable());
            QObject::connect(c, &KDecoration3::DecoratedWindow::closeableChanged, b, &WindowPerch::Button::setVisible);
            break;

        case DecorationButtonType::Maximize:
            b->setVisible(c->isMaximizeable());
            QObject::connect(c, &KDecoration3::DecoratedWindow::maximizeableChanged, b, &WindowPerch::Button::setVisible);
            break;

        case DecorationButtonType::Minimize:
            b->setVisible(c->isMinimizeable());
            QObject::connect(c, &KDecoration3::DecoratedWindow::minimizeableChanged, b, &WindowPerch::Button::setVisible);
            break;

        case DecorationButtonType::ContextHelp:
            b->setVisible(c->providesContextHelp());
            QObject::connect(c, &KDecoration3::DecoratedWindow::providesContextHelpChanged, b, &WindowPerch::Button::setVisible);
            break;

        case DecorationButtonType::Shade:
            b->setVisible(c->isShadeable());
            QObject::connect(c, &KDecoration3::DecoratedWindow::shadeableChanged, b, &WindowPerch::Button::setVisible);
            break;

        case DecorationButtonType::Menu:
            QObject::connect(c, &KDecoration3::DecoratedWindow::iconChanged, b, [b]() {
                b->update();
            });
            break;

        default:
            break;
        }

        return b;
    }

    return nullptr;
}

//__________________________________________________________________
void Button::paint(QPainter *painter, const QRectF &repaintRegion)
{
    Q_UNUSED(repaintRegion)

    if (!decoration()) {
        return;
    }

    switch (type()) {
    case KDecoration3::DecorationButtonType::Menu: {
        const QRectF iconRect = geometry().marginsRemoved(m_padding);
        const auto c = decoration()->window();
        if (auto deco = qobject_cast<Decoration *>(decoration())) {
            const QPalette activePalette = KIconLoader::global()->customPalette();
            QPalette palette = c->palette();
            palette.setColor(QPalette::WindowText, deco->fontColor());
            KIconLoader::global()->setCustomPalette(palette);
            c->icon().paint(painter, iconRect.toRect());
            if (activePalette == QPalette()) {
                KIconLoader::global()->resetPalette();
            } else {
                KIconLoader::global()->setCustomPalette(palette);
            }
        } else {
            c->icon().paint(painter, iconRect.toRect());
        }
        break;
    }
    case KDecoration3::DecorationButtonType::Spacer:
        break;
    default:
        painter->save();
        drawIcon(painter);
        painter->restore();
        break;
    }
}

//__________________________________________________________________
void Button::drawIcon(QPainter *painter) const
{
    painter->setRenderHints(QPainter::Antialiasing);

    /*
    scale painter so that its window matches QRect( -1, -1, 20, 20 )
    this makes all further rendering and scaling simpler
    all further rendering is performed inside QRect( 0, 0, 18, 18 )
    */
    const QRectF rect = geometry().marginsRemoved(m_padding);
    painter->translate(rect.topLeft());

    const qreal width(rect.width());
    painter->scale(width / 20, width / 20);
    painter->translate(1, 1);

    // Window Perch: the button is a cat head (two ears) instead of Breeze's circle. At rest it
    // is a soft silhouette in the title text colour; on hover/press it fills with Breeze's
    // hover colour (red for close) and the "eyes" (the button symbol) appear.
    QPainterPath head;
    head.moveTo(2.6, 1.0);
    head.lineTo(6.4, 4.2);
    head.quadTo(9.0, 3.6, 11.6, 4.2);
    head.lineTo(15.4, 1.0);
    head.quadTo(16.4, 4.6, 16.3, 7.0);
    head.cubicTo(17.6, 9.2, 17.4, 17.6, 9.0, 17.6);
    head.cubicTo(0.6, 17.6, 0.4, 9.2, 1.7, 7.0);
    head.quadTo(1.6, 4.6, 2.6, 1.0);
    head.closeSubpath();

    // Eyes only on hover/press; sticky toggles (keep above/below, all desktops, shade) also show them while on.
    const bool isToggle = type() != DecorationButtonType::Maximize && type() != DecorationButtonType::Minimize && type() != DecorationButtonType::Close;
    const bool showEyes = isHovered() || isPressed() || (isToggle && isChecked());
    const QColor backgroundColor(this->backgroundColor());
    painter->setPen(Qt::NoPen);
    if (backgroundColor.isValid()) {
        painter->setBrush(backgroundColor);
    } else {
        auto d = qobject_cast<Decoration *>(decoration());
        QColor rest = d ? d->fontColor() : this->foregroundColor();
        rest.setAlphaF(rest.alphaF() * (isEnabled() ? 0.28 : 0.12));
        painter->setBrush(rest);
    }
    painter->drawPath(head);

    if (!showEyes) {
        return;
    }

    // eyes sit on this line, one per side
    constexpr qreal ey = 10.9;
    constexpr qreal lx = 6.0;
    constexpr qreal rx = 12.0;

    // render mark
    const QColor foregroundColor(this->foregroundColor());
    if (foregroundColor.isValid()) {
        // setup painter
        QPen pen(foregroundColor);
        pen.setCapStyle(Qt::RoundCap);
        pen.setJoinStyle(Qt::MiterJoin);
        pen.setWidthF(PenWidth::Symbol * qMax((qreal)1.0, 20 / width));

        painter->setPen(pen);
        painter->setBrush(Qt::NoBrush);

        switch (type()) {
        case DecorationButtonType::Close: {
            // x x
            for (const qreal x : {lx, rx}) {
                painter->drawLine(QPointF(x - 1.4, ey - 1.4), QPointF(x + 1.4, ey + 1.4));
                painter->drawLine(QPointF(x + 1.4, ey - 1.4), QPointF(x - 1.4, ey + 1.4));
            }
            break;
        }

        case DecorationButtonType::Maximize: {
            if (isChecked()) {
                pen.setJoinStyle(Qt::RoundJoin);
                painter->setPen(pen);

                // ^ ^ (restore)
                for (const qreal x : {lx, rx}) {
                    painter->drawPolyline(QVector<QPointF>{QPointF(x - 1.6, ey + 0.8), QPointF(x, ey - 0.8), QPointF(x + 1.6, ey + 0.8)});
                }
            } else {
                // o o (maximize)
                for (const qreal x : {lx, rx}) {
                    painter->drawEllipse(QPointF(x, ey), 1.4, 1.4);
                }
            }
            break;
        }

        case DecorationButtonType::Minimize: {
            // - - (minimize)
            for (const qreal x : {lx, rx}) {
                painter->drawLine(QPointF(x - 1.7, ey), QPointF(x + 1.7, ey));
            }
            break;
        }

        case DecorationButtonType::OnAllDesktops: {
            // . . (pinned: big round eyes)
            painter->setPen(Qt::NoPen);
            painter->setBrush(foregroundColor);
            const qreal r = isChecked() ? 1.5 : 0.9;
            for (const qreal x : {lx, rx}) {
                painter->drawEllipse(QPointF(x, ey), r, r);
            }
            break;
        }

        case DecorationButtonType::Shade: {
            // = = (shade)
            for (const qreal x : {lx, rx}) {
                painter->drawLine(QPointF(x - 1.6, ey - 0.9), QPointF(x + 1.6, ey - 0.9));
                painter->drawLine(QPointF(x - 1.6, ey + 0.9), QPointF(x + 1.6, ey + 0.9));
            }

            break;
        }

        case DecorationButtonType::KeepBelow: {
            // v v (keep below)
            for (const qreal x : {lx, rx}) {
                painter->drawPolyline(QVector<QPointF>{QPointF(x - 1.6, ey - 0.8), QPointF(x, ey + 0.8), QPointF(x + 1.6, ey - 0.8)});
            }
            break;
        }

        case DecorationButtonType::KeepAbove: {
            // ^ ^ raised (keep above)
            for (const qreal x : {lx, rx}) {
                painter->drawPolyline(QVector<QPointF>{QPointF(x - 1.6, ey - 0.2), QPointF(x, ey - 1.8), QPointF(x + 1.6, ey - 0.2)});
            }
            break;
        }

        case DecorationButtonType::ExcludeFromCapture: {
            // A spy hat (like view-private.svg icon)
            const qreal cx = 9, cy = 9;
            // Hat crown with dip/crease at top (filled)
            std::array crownPoints{QPointF(cx - 4.1, cy - 2.5),
                                   QPointF(cx - 3.2, cy - 6.1),
                                   QPointF(cx, cy - 5),
                                   QPointF(cx + 3.2, cy - 6.1),
                                   QPointF(cx + 4.1, cy - 2.5)};
            painter->setBrush(pen.color());
            painter->drawPolygon(crownPoints.data(), crownPoints.size());
            painter->setBrush(Qt::NoBrush);
            // Hat brim
            painter->drawLine(QPointF(cx - 6.2, cy - 0.5), QPointF(cx + 6.2, cy - 0.5));
            // Glasses' lenses
            painter->drawEllipse(QPointF(cx - 4, cy + 3.8), 2.3, 2.3);
            painter->drawEllipse(QPointF(cx + 4, cy + 3.8), 2.3, 2.3);
            // Bridge between lenses
            painter->drawLine(QPointF(cx - 1.5, cy + 3.8), QPointF(cx + 1.5, cy + 3.8));
            break;
        }

        case DecorationButtonType::ApplicationMenu: {
            painter->drawRect(QRectF(3.5, 4.5, 11, 1));
            painter->drawRect(QRectF(3.5, 8.5, 11, 1));
            painter->drawRect(QRectF(3.5, 12.5, 11, 1));
            break;
        }

        case DecorationButtonType::ContextHelp: {
            QPainterPath path;
            path.moveTo(5, 6);
            path.arcTo(QRectF(5, 3.5, 8, 5), 180, -180);
            path.cubicTo(QPointF(12.5, 9.5), QPointF(9, 7.5), QPointF(9, 11.5));
            painter->drawPath(path);

            painter->drawRect(QRectF(9, 15, 0.5, 0.5));

            break;
        }

        default:
            break;
        }
    }
}

//__________________________________________________________________
QColor Button::foregroundColor() const
{
    auto d = qobject_cast<Decoration *>(decoration());
    if (!d) {
        return QColor();

    } else if (isPressed()) {
        return d->titleBarColor();

    } else if (type() == DecorationButtonType::Close && d->internalSettings()->outlineCloseButton()) {
        return d->titleBarColor();

    } else if ((type() == DecorationButtonType::KeepBelow || type() == DecorationButtonType::KeepAbove || type() == DecorationButtonType::Shade
                || type() == DecorationButtonType::ExcludeFromCapture)
               && isChecked()) {
        return d->titleBarColor();

    } else if (m_animation->state() == QAbstractAnimation::Running) {
        return KColorUtils::mix(d->fontColor(), d->titleBarColor(), m_opacity);

    } else if (isHovered()) {
        return d->titleBarColor();

    } else {
        return d->fontColor();
    }
}

//__________________________________________________________________
QColor Button::backgroundColor() const
{
    auto d = qobject_cast<Decoration *>(decoration());
    if (!d) {
        return QColor();
    }

    auto c = d->window();
    QColor redColor(c->color(ColorGroup::Warning, ColorRole::Foreground));

    if (isPressed()) {
        if (type() == DecorationButtonType::Close) {
            return redColor.darker();
        } else {
            return KColorUtils::mix(d->titleBarColor(), d->fontColor(), 0.3);
        }

    } else if ((type() == DecorationButtonType::KeepBelow || type() == DecorationButtonType::KeepAbove || type() == DecorationButtonType::Shade)
               && isChecked()) {
        return d->fontColor();
    } else if (type() == DecorationButtonType::ExcludeFromCapture && isChecked()) {
        return redColor;
    } else if (m_animation->state() == QAbstractAnimation::Running) {
        if (type() == DecorationButtonType::Close) {
            if (d->internalSettings()->outlineCloseButton()) {
                return c->isActive() ? KColorUtils::mix(redColor, redColor.lighter(), m_opacity) : KColorUtils::mix(redColor.lighter(), redColor, m_opacity);

            } else {
                QColor color(redColor.lighter());
                color.setAlpha(color.alpha() * m_opacity);
                return color;
            }

        } else {
            QColor color(d->fontColor());
            color.setAlpha(color.alpha() * m_opacity);
            return color;
        }

    } else if (isHovered()) {
        if (type() == DecorationButtonType::Close) {
            return c->isActive() ? redColor.lighter() : redColor;
        } else {
            return d->fontColor();
        }

    } else if (type() == DecorationButtonType::Close && d->internalSettings()->outlineCloseButton()) {
        return c->isActive() ? redColor : d->fontColor();

    } else {
        return QColor();
    }
}

//________________________________________________________________
void Button::reconfigure()
{
    // animation
    auto d = qobject_cast<Decoration *>(decoration());
    if (!d) {
        return;
    }

    switch (type()) {
    case KDecoration3::DecorationButtonType::Spacer:
        setPreferredSize(QSizeF(d->buttonSize() * 0.5, d->buttonSize()));
        break;
    default:
        setPreferredSize(QSizeF(d->buttonSize(), d->buttonSize()));
        break;
    }

    m_animation->setDuration(d->animationsDuration());
}

//__________________________________________________________________
void Button::updateAnimationState(bool hovered)
{
    auto d = qobject_cast<Decoration *>(decoration());
    if (!(d && d->animationsDuration() > 0)) {
        return;
    }

    m_animation->setDirection(hovered ? QAbstractAnimation::Forward : QAbstractAnimation::Backward);
    if (m_animation->state() != QAbstractAnimation::Running) {
        m_animation->start();
    }
}

} // namespace
