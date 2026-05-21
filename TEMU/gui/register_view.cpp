#include "register_view.h"
#include "temu_wrapper.h"
#include <QHeaderView>
#include <QColor>
#include <QBrush>
#include <QTimer>

RegisterView::RegisterView(QWidget *parent)
    : QWidget(parent), m_firstUpdate(true)
{
    QVBoxLayout *layout = new QVBoxLayout(this);
    
    m_titleLabel = new QLabel("Registers", this);
    m_titleLabel->setStyleSheet("font-weight: bold; font-size: 12pt;");
    layout->addWidget(m_titleLabel);
    
    m_table = new QTableWidget(33, 3, this); // 32 registers + PC
    m_table->setHorizontalHeaderLabels(QStringList() << "Register" << "Hex" << "Decimal");
    m_table->verticalHeader()->setVisible(false);
    m_table->setEditTriggers(QAbstractItemView::DoubleClicked);
    m_table->setSelectionBehavior(QAbstractItemView::SelectRows);
    m_table->setAlternatingRowColors(true);
    
    // Set column widths
    m_table->setColumnWidth(0, 100);
    m_table->setColumnWidth(1, 120);
    m_table->setColumnWidth(2, 120);
    
    // Initialize previous values
    for (int i = 0; i < 33; i++) {
        m_previousRegisters[i] = 0;
    }
    
    layout->addWidget(m_table);
    setLayout(layout);
}

void RegisterView::updateRegisters()
{
    struct CPUStateWrapper state;
    temu_get_cpu_state(&state);
    
    // Update registers
    for (int i = 0; i < 32; i++) {
        QTableWidgetItem *nameItem = new QTableWidgetItem(temu_get_register_name(i));
        nameItem->setFlags(nameItem->flags() & ~Qt::ItemIsEditable);
        
        QTableWidgetItem *hexItem = new QTableWidgetItem(
            QString("0x%1").arg(state.registers[i], 8, 16, QChar('0')).toUpper());
        hexItem->setFlags(hexItem->flags() & ~Qt::ItemIsEditable);
        
        QTableWidgetItem *decItem = new QTableWidgetItem(
            QString::number(state.registers[i]));
        decItem->setFlags(decItem->flags() & ~Qt::ItemIsEditable);
        
        if (!m_firstUpdate && m_previousRegisters[i] != state.registers[i]) {
            // Highlight changed register
            hexItem->setBackground(QBrush(QColor(255, 255, 200)));
            decItem->setBackground(QBrush(QColor(255, 255, 200)));
        }
        
        m_table->setItem(i, 0, nameItem);
        m_table->setItem(i, 1, hexItem);
        m_table->setItem(i, 2, decItem);
        
        m_previousRegisters[i] = state.registers[i];
    }
    
    // Update PC
    QTableWidgetItem *pcNameItem = new QTableWidgetItem("$pc");
    pcNameItem->setFlags(pcNameItem->flags() & ~Qt::ItemIsEditable);
    
    QTableWidgetItem *pcHexItem = new QTableWidgetItem(
        QString("0x%1").arg(state.pc, 8, 16, QChar('0')).toUpper());
    pcHexItem->setFlags(pcHexItem->flags() & ~Qt::ItemIsEditable);
    
    QTableWidgetItem *pcDecItem = new QTableWidgetItem(
        QString::number(state.pc));
    pcDecItem->setFlags(pcDecItem->flags() & ~Qt::ItemIsEditable);
    
    if (!m_firstUpdate && m_previousRegisters[32] != state.pc) {
        pcHexItem->setBackground(QBrush(QColor(200, 255, 200)));
        pcDecItem->setBackground(QBrush(QColor(200, 255, 200)));
    }
    
    m_table->setItem(32, 0, pcNameItem);
    m_table->setItem(32, 1, pcHexItem);
    m_table->setItem(32, 2, pcDecItem);
    
    m_previousRegisters[32] = state.pc;
    m_firstUpdate = false;
}

void RegisterView::highlightChangedRegisters()
{
    // This is called after a short delay to remove highlights
    QTimer::singleShot(500, this, [this]() {
        for (int i = 0; i < 33; i++) {
            for (int j = 1; j < 3; j++) {
                QTableWidgetItem *item = m_table->item(i, j);
                if (item) {
                    item->setBackground(QBrush());
                }
            }
        }
    });
}

