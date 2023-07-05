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

    explicit NameDerivationTable(QObject *parent = nullptr);
    int rowCount(const QModelIndex & = QModelIndex()) const override { return m_table.size(); }
    int columnCount(const QModelIndex & = QModelIndex()) const override { return m_table.at(0).size(); }

    void clicked(int row, int column,
                 DeletionLocationOption deleteNumberLocationOption,
                 int deleteNumberCount,
                 DeletionLocationOption deleteCharsLocationOption,
                 QString deleteCharsText,
                 QString replaceFrom,
                 QString replaceTo,
                 Qt::CaseSensitivity caseSensitivity,
                 QString delimiter,
                 DelimiterCounterOption delimiterCounterOption,
                 bool firstNameFirst);
    Q_INVOKABLE void editData(int row, int column, QString text);

    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addPerson(QString fileName, QString baseName) {
        beginInsertRows(QModelIndex(), rowCount(), rowCount());
        m_table.append({
            "",
            "",
            fileName
        });
        m_baseName.append(baseName);
        m_overrideAutomatic.append(false);
        m_exclude.append(false);
        endInsertRows();
    }

    QList<int> delimiterPlaces(QString s, QString delimiter);

    void separateStringToNames(QString stripped, QString *firstName, QString *familyName, QString delimiter, QList<int> occasions, DelimiterCounterOption option, bool firstNameFirst);

    QString deleteNumberOfChars(QString s, DeletionLocationOption deleteNumberLocationOption, int deleteNumberCount);

    QString deleteSpecialChars(QString s, DeletionLocationOption deleteCharsLocationOption, QString deleteCharsText);

    QString replaceFromChunk(QString s, QString from, Qt::CaseSensitivity caseSensitivity);

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

    void deriveOneName(int i,
                         DeletionLocationOption deleteNumberLocationOption,
                         int deleteNumberCount,
                         DeletionLocationOption deleteCharsLocationOption,
                         QString deleteCharsText,
                         QString replaceFrom,
                         QString replaceTo,
                         Qt::CaseSensitivity caseSensitivity,
                         QString delimiter,
                         DelimiterCounterOption delimiterCounterOption,
                         bool firstNameFirst) {

        if (m_overrideAutomatic.at(i) || m_exclude.at(i)) return;
        QString stripped = m_baseName.at(i);

        stripped = deleteNumberOfChars(stripped, deleteNumberLocationOption, deleteNumberCount);
        stripped = deleteSpecialChars(stripped, deleteCharsLocationOption, deleteCharsText);
        stripped = replace(stripped, replaceFrom, replaceTo, caseSensitivity);


        auto delimiterList = delimiterPlaces(stripped,delimiter);
        separateStringToNames(stripped,&m_table[i][0], &m_table[i][1], delimiter, delimiterList, delimiterCounterOption, firstNameFirst);

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
           deriveOneName(i, deleteNumberLocationOption,
                         deleteNumberCount,
                         deleteCharsLocationOption,
                         deleteCharsText,
                         replaceFrom,
                         replaceTo,
                         caseSensitivity,
                          delimiter,
                         delimiterCounterOption,
                         firstNameFirst);
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
