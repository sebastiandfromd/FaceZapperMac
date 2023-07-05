#include "namederivationtable.h"



NameDerivationTable::NameDerivationTable(QObject *parent) : QAbstractTableModel(parent) {
    m_table.append({
        "Vorname",
        "Nachname",
        "Datei",
    });
    m_overrideAutomatic.append(false);
    m_exclude.append(false);
    m_baseName.append(QString());
}

void NameDerivationTable::clicked(int row, int column, DeletionLocationOption deleteNumberLocationOption, int deleteNumberCount, DeletionLocationOption deleteCharsLocationOption, QString deleteCharsText, QString replaceFrom, QString replaceTo, Qt::CaseSensitivity caseSensitivity, QString delimiter, DelimiterCounterOption delimiterCounterOption, bool firstNameFirst) {
    Q_UNUSED(column);
    if (m_overrideAutomatic.at(row)) {
        m_overrideAutomatic[row] = false;
        m_exclude[row] = true;
    } else if (m_exclude.at(row)) {
        m_exclude[row] = false;
        deriveOneName(row, deleteNumberLocationOption,
                      deleteNumberCount,
                      deleteCharsLocationOption,
                      deleteCharsText,
                      replaceFrom,
                      replaceTo,
                      caseSensitivity,
                      delimiter,
                      delimiterCounterOption,
                      firstNameFirst);
    } else {
        m_overrideAutomatic[row] = true;
    }
    auto index1 = this->index(row,0);
    auto index2 = this->index(row,2);
    emit dataChanged(index1, index2);
}

void NameDerivationTable::editData(int row, int column, QString text) {
    if (text == m_table[row][column]) return;
    m_table[row][column]=text;
    auto index = this->index(row, column);
    emit dataChanged(index, index);
}

QVariant NameDerivationTable::data(const QModelIndex &index, int role) const {
    Q_ASSERT(m_table.count() == m_overrideAutomatic.count());
    Q_ASSERT(m_table.count() == m_exclude.count());
    switch (role) {
    case TableDataRole: {
        return m_table.at(index.row()).at(index.column());
    }
    case HeadingRole: {
        return index.row() == 0;
    }
    case OverrideAutomaticRole: {
        return m_overrideAutomatic.at(index.row());
    }
    case ExcludeRole: {
        return m_exclude.at(index.row());
    }
    default: break;
    }
    return QVariant();
}

QHash<int, QByteArray> NameDerivationTable::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[TableDataRole] = "tabledata";
    roles[HeadingRole] = "heading";
    roles[OverrideAutomaticRole] = "overrideAutomatic";
    roles[ExcludeRole] = "exclude";
    return roles;
}

QList<int> NameDerivationTable::delimiterPlaces(QString s, QString delimiter) {
    QList<int> result;
    if (delimiter.isEmpty() || s.isEmpty()) return result;
    for (int i = 0; i < (s.length()+1-delimiter.length()); i++){
        if (s.mid(i,delimiter.length()) == delimiter) {
            result << i;
        }
    }
    return result;
}

void NameDerivationTable::separateStringToNames(QString stripped, QString *firstName, QString *familyName, QString delimiter, QList<int> occasions, DelimiterCounterOption option, bool firstNameFirst) {
    int position = -1;
    if (occasions.count() == 0
        || (occasions.count() == 1 &&
            (option == NameDerivationTable::DelimiterCounterOption::SECOND_FROM_LEFT
             || option == NameDerivationTable::DelimiterCounterOption::SECOND_FROM_RIGHT)
            )
        ) {
        // give up if it is impossible to separate within given requiements
    } else if (occasions.count() == 1) {
        //easy choice, as the "SECOND_..." options have been handled above already
        position = occasions.first();
    } else if (occasions.count() == 2) {
        if (option == NameDerivationTable::DelimiterCounterOption::FIRST_FROM_LEFT
            || option == NameDerivationTable::DelimiterCounterOption::SECOND_FROM_RIGHT
            || option == NameDerivationTable::DelimiterCounterOption::MIDDLE_LEFT) {
            position = occasions.first();
        } else {
            position = occasions.last();
        }
    } else if (occasions.count() > 2) {
        switch (option) {
        case DelimiterCounterOption::FIRST_FROM_LEFT: position = occasions.first(); break;
        case DelimiterCounterOption::FIRST_FROM_RIGHT: ; position = occasions.last(); break;
        case DelimiterCounterOption::SECOND_FROM_LEFT: ; position = occasions.at(2); break;
        case DelimiterCounterOption::SECOND_FROM_RIGHT: ; position = occasions.at(occasions.count()-2); break;
        case DelimiterCounterOption::MIDDLE_LEFT: position = occasions.at(qCeil(occasions.count()/2)-1); break;
        case DelimiterCounterOption::MIDDLE_RIGHT: position = occasions.at(qFloor(occasions.count()/2)); break;
        }
    }

    if (position >= 0) {
        // we have a valid position, let's cut
        *firstName = stripped.left(position);
        *familyName  = stripped.right(stripped.length() - (position + delimiter.length()));
        if (!firstNameFirst) swap(*firstName, *familyName);
    } else {
        // we do not have a valid position. we give up.
        *firstName = stripped;
        *familyName = QString();
    }
}

QString NameDerivationTable::deleteNumberOfChars(QString s, DeletionLocationOption deleteNumberLocationOption, int deleteNumberCount) {
    if (deleteNumberCount == 0) return s;
    // We don't handle
    // DeletionLocationOption::ALL and DeletionLocationOption::NOT,
    // because UI doesn't let user choose them for deleting a *number*.
    if (deleteNumberLocationOption == DeletionLocationOption::LEFT
        || deleteNumberLocationOption == DeletionLocationOption::SIDES) {
        if (deleteNumberCount >= s.length()) return QString();
        s = s.right(s.length()-deleteNumberCount);
    }
    if (deleteNumberLocationOption == DeletionLocationOption::RIGHT
        || deleteNumberLocationOption == DeletionLocationOption::SIDES) {
        if (deleteNumberCount >= s.length()) return QString();
        s = s.left(s.length()-deleteNumberCount);
    }
    return s;
}

QString NameDerivationTable::deleteSpecialChars(QString s, DeletionLocationOption deleteCharsLocationOption, QString deleteCharsText) {
    if (deleteCharsLocationOption == DeletionLocationOption::NOT) return s;
    if (deleteCharsLocationOption == DeletionLocationOption::RIGHT
        ||deleteCharsLocationOption == DeletionLocationOption::SIDES) {
        while (!s.isEmpty() && deleteCharsText.contains(s.right(1))) s.remove(s.length()-1,1);
    }
    if (deleteCharsLocationOption == DeletionLocationOption::LEFT
        ||deleteCharsLocationOption == DeletionLocationOption::SIDES) {
        while (!s.isEmpty() && deleteCharsText.contains(s.left(1))) s.remove(0,1);
    }
    if (deleteCharsLocationOption == DeletionLocationOption::ALL) {
        QString t;
        for (int i = 0; i < s.length(); i++) {
            if (!deleteCharsText.contains(s.at(i))) t.append(s.at(i));
        }
        return t;
    }
    return s;
}

QString NameDerivationTable::replaceFromChunk(QString s, QString from, Qt::CaseSensitivity caseSensitivity) {
    QString result;
    auto letters = QStringLiteral("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZäÄöÖüÜßẞÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕØÙÛÝàáâãåæçèéêëìíîïñòóôõøùúûýÿĀāĂăĄąĆćĈĉĊċČčĎďÐĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžƀƁƊƓǍǎǑǒǓǔǕǖǘǏǐǙǚǛǜǝǞǟǠǡǢǣǤǥǦǧǨǩǪǫǬǭǱǲǳǴǵǸǹǺǻǼǽǾǿȀȁȂȃȄȅȆȇȈȉȊȋȌȍȎȏȐȑȒȓȔȕȖȗȘșȚțȞȟȤȥȦȧȨȩȪȫȬȭȮȯȰȱȲȳ");
    auto numbers = QStringLiteral("0123456789");
    bool cs = (caseSensitivity == Qt::CaseSensitive);
    bool special = false;
    bool noMatch = false;

    for (int i = 0; i< from.length(); i++) {
        if (from.at(i)=='/') {
            special = true;
            continue;
        } else if (special) {
            special = false;
            switch (from.at(i).toLatin1()) {
            case '?': // anyChar
                result.append(s.first(1));
                s.removeFirst();
                break;
            case '#': // anyNumeral
                if (!s.isEmpty() && numbers.contains(s.first(1))) {
                    result.append(s.first(1));
                    s.removeFirst();
                } else {
                    noMatch = true;
                }
                ; break;
            case '$': //anyLetter
                if (!s.isEmpty() && letters.contains(s.first(1))) {
                    result.append(s.first(1));
                    s.removeFirst();
                } else {
                    noMatch = true;
                }
                ; break;
            case '%': //anyNumber
                if (!s.isEmpty() && numbers.contains(s.first(1))) {
                    result.append(s.first(1));
                    s.removeFirst();
                    while (!s.isEmpty() && numbers.contains(s.first(1))) {
                        result.append(s.first(1));
                        s.removeFirst();
                    }
                } else {
                    noMatch = true;
                }
                ; break;
            case 'W': //anyWord
                if (!s.isEmpty() && letters.contains(s.first(1))) {
                    result.append(s.first(1));
                    s.removeFirst();
                    while (!s.isEmpty() && letters.contains(s.first(1))) {
                        result.append(s.first(1));
                        s.removeFirst();
                    }
                } else {
                    noMatch = true;
                }
                ; break;
            }
        } else {
            // no special character
            if (!s.isEmpty() && (from.at(i) == s.first(1) || (!cs && (from.at(i).toUpper() == s.first(1).toUpper())))) {
                result.append(s.first(1));
                s.removeFirst();
            } else {
                noMatch = true;
            }
        }
        if (noMatch) break;
    }

    if (noMatch) result = QString();
    return result;
    }
