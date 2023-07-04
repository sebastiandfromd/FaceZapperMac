#ifndef NAMEDERIVATIONTABLE_H
#define NAMEDERIVATIONTABLE_H

#include <QAbstractTableModel >
#include <QObject>
#include <QRandomGenerator>
#include <QString>

class NameDerivationTable : public QAbstractTableModel {
    Q_OBJECT
    enum TableRoles { TableDataRole = Qt::UserRole + 1, HeadingRole, OverrideAutomaticRole, ExcludeRole};
public:
    enum class DelimiterCounterOption {
        FIRST_FROM_LEFT = 0,
        FIRST_FROM_RIGHT = 1,
        SECOND_FROM_LEFT = 2,
        SECOND_FROM_RIGHT = 3,
        MIDDLE_LEFT = 4,
        MIDDLE_RIGHT = 5
    };
    Q_ENUM(DelimiterCounterOption)

    enum class DeletionLocationOption {
        LEFT = 0,
        RIGHT = 1,
        SIDES = 2,
        NOT = 3,
        ALL = 4
    };
    Q_ENUM(DeletionLocationOption)

    explicit NameDerivationTable(QObject *parent = nullptr) : QAbstractTableModel(parent) {
        m_table.append({
            "Vorname",
            "Nachname",
            "Datei",
        });
        m_overrideAutomatic.append(false);
        m_exclude.append(false);
        m_baseName.append(QString());
    }
    int rowCount(const QModelIndex & = QModelIndex()) const override {
        return m_table.size();
    }

    int columnCount(const QModelIndex & = QModelIndex()) const override {
        return m_table.at(0).size();
    }

    Q_INVOKABLE void clicked(int row, int column) {
        qDebug()<< "row: "<<row;
        qDebug()<< "column: "<<column;
        qDebug()<< "table.at(row).at(column): "<<m_table.at(row).at(column);
        qDebug()<<m_table.at(row-1).at(column);
    }
    Q_INVOKABLE void editData(int row, int column, QString text) {
        m_table[row][column]=text;
    }

    QVariant data(const QModelIndex &index, int role) const override {
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
    QHash<int, QByteArray> roleNames() const override {
        QHash<int, QByteArray> roles;
        roles[TableDataRole] = "tabledata";
        roles[HeadingRole] = "heading";
        roles[OverrideAutomaticRole] = "overrideAutomatic";
        roles[ExcludeRole] = "exclude";
        return roles;
    }

    Q_INVOKABLE void addPerson(QString fileName, QString baseName) {
        beginInsertRows(QModelIndex(), rowCount(), rowCount());
        m_table.append({
            "",
            "",
            fileName
        });
        m_baseName.append(baseName);
        m_overrideAutomatic.append(false);   //QRandomGenerator::global()->bounded(0,3) == 0);
        m_exclude.append(false);     //QRandomGenerator::global()->bounded(0,10) == 0);
        endInsertRows();
    }

    QList<int> delimiterPlaces(QString s, QString delimiter) {
        QList<int> result;
        if (delimiter.isEmpty() || s.isEmpty()) return result;
        for (int i = 0; i < (s.length()+1-delimiter.length()); i++){
            if (s.mid(i,delimiter.length()) == delimiter) {
                result << i;
            }
        }
        return result;
    }

    void separateStringToPerson(QString stripped, QString *firstName, QString *familyName, QString delimiter, QList<int> occasions, DelimiterCounterOption option, bool firstNameFirst) {
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

    QString deleteNumber(QString s, DeletionLocationOption deleteNumberLocationOption, int deleteNumberCount) {
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

    QString deleteChars(QString s, DeletionLocationOption deleteCharsLocationOption, QString deleteCharsText) {
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

    QString replaceFromChunk(QString s, QString from, Qt::CaseSensitivity caseSensitivity) {
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

    QString replace(QString s, QString from, QString to, Qt::CaseSensitivity caseSensitivity) {
        // special placeholder keys
        // any char ^? (from)
        // any numeral ^# (from)
        // any letter ^$ (from)
        // any number ^% (from)
        // any letters ^W (from)
        // "search "from" text ^& (to)

        for (int i = 0; i < s.length(); i++){
           auto searchResult = replaceFromChunk(s.right(s.length()-i),from,caseSensitivity);
           if (!searchResult.isEmpty()) {
                QString currentTo = to;
                currentTo.replace("/&",searchResult,caseSensitivity);
                s.replace(i,searchResult.length(),currentTo);
                i += currentTo.length()-1;
           }
        }
        return s;
    }

    void runNameDerivation(DeletionLocationOption deleteNumberLocationOption,
                           int deleteNumberCount,
                           DeletionLocationOption deleteCharsLocationOption,
                           QString deleteCharsText,
                           QString replaceFrom,
                           QString replaceTo,
                           Qt::CaseSensitivity caseSensitivity,
                           QString delimiter,
                           DelimiterCounterOption delimiterCounterOption,
                           bool firstNameFirst) {
        beginResetModel();
        for (int i = 1; i < m_table.count(); i++) {
            if (m_overrideAutomatic.at(i) || m_exclude.at(i)) continue;
            QString stripped = m_baseName.at(i);

            stripped = deleteNumber(stripped, deleteNumberLocationOption, deleteNumberCount);
            stripped = deleteChars(stripped, deleteCharsLocationOption, deleteCharsText);
            stripped = replace(stripped, replaceFrom, replaceTo, caseSensitivity);


            auto delimiterList = delimiterPlaces(stripped,delimiter);
            separateStringToPerson(stripped,&m_table[i][0], &m_table[i][1], delimiter, delimiterList, delimiterCounterOption, firstNameFirst);
        }
        endResetModel();
    }
private:
    QVector<QVector<QString>> m_table;
    QVector<QString> m_baseName;
    QVector<bool> m_overrideAutomatic;
    QVector<bool> m_exclude;
};

#endif // NAMEDERIVATIONTABLE_H
