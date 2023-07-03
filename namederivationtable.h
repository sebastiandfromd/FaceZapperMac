#ifndef NAMEDERIVATIONTABLE_H
#define NAMEDERIVATIONTABLE_H

#include <QAbstractTableModel >
#include <QObject>
#include <QRandomGenerator>
#include <QString>
#include "persondata.h"

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



    QString stripBaseName(QString baseName) {
        auto stripChars = QStringLiteral(" ^°§$%&/()=`´*+~'#<>|;,.-_/*{[]}€@0123456789");
        while (stripChars.contains(baseName.right(1))) baseName.remove(baseName.length()-1,1);
        while (stripChars.contains(baseName.left(1))) baseName.remove(0,1);
        return baseName;
    }
    Q_INVOKABLE void addPerson(QString fileName, QString baseName) {
        beginInsertRows(QModelIndex(), rowCount(), rowCount());
        baseName = stripBaseName(baseName);
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
//            qDebug()<<s.mid(i,delimiter.length());
            if (s.mid(i,delimiter.length()) == delimiter) {
                result << i;
            }
        }
        return result;
    }

    QString leftStringAt(QString s, int pos) {
        return s.left(pos);
    }
    QString rightStringAt(QString s, int pos, int cutAway) {
       return s.right(s.length()-(pos+cutAway));
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
            //easy choice, as the "SECOND..." options have been handled above already
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
            // we have a valid position
            *firstName = leftStringAt(stripped, position);
            *familyName  = rightStringAt(stripped, position, delimiter.length());
            if (!firstNameFirst) swap(*firstName, *familyName);
        } else {
            // we do not have a valid position. we give up.
           *firstName = stripped;
           *familyName = QString();
        }
    }

    void runNameDerivation(QString delimiter, QString replaceFrom, QString replaceTo, int delimiterCounterIndex, bool firstNameFirst) {
        beginResetModel();
        for (int i = 1; i < m_table.count(); i++) {
            if (m_overrideAutomatic.at(i) || m_exclude.at(i)) continue;
            QString stripped = m_baseName.at(i);





            auto delimiterList = delimiterPlaces(stripped,delimiter);
            DelimiterCounterOption delimiterCounterOption = static_cast<DelimiterCounterOption>(delimiterCounterIndex);
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
