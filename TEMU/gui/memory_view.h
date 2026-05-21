#ifndef MEMORY_VIEW_H
#define MEMORY_VIEW_H

#include <QWidget>
#include <QTableWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QComboBox>
#include <QLineEdit>
#include <QPushButton>
#include <cstdint>

class MemoryView : public QWidget
{
    Q_OBJECT

public:
    explicit MemoryView(QWidget *parent = nullptr);
    void updateMemory();
    void setAddressRange(uint32_t start, uint32_t end);
    void jumpToAddress(uint32_t addr);

private slots:
    void onSegmentChanged(int index);
    void onJumpClicked();
    void onTableItemChanged(QTableWidgetItem *item);

private:
    void setupTable();
    void fillMemoryTable(uint32_t startAddr, uint32_t endAddr);
    void updateMemoryCell(int row, int col, uint32_t addr);

    QTableWidget *m_table;
    QLabel *m_titleLabel;
    QComboBox *m_segmentCombo;
    QLineEdit *m_addressEdit;
    QPushButton *m_jumpButton;
    
    uint32_t m_startAddr;
    uint32_t m_endAddr;
    bool m_updating;
};

#endif // MEMORY_VIEW_H

