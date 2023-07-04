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
