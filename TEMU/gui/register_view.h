#ifndef REGISTER_VIEW_H
#define REGISTER_VIEW_H

#include <QWidget>
#include <QTableWidget>
#include <QVBoxLayout>
#include <QLabel>

class RegisterView : public QWidget
{
    Q_OBJECT

public:
    explicit RegisterView(QWidget *parent = nullptr);
    void updateRegisters();
    void highlightChangedRegisters();

private:
    QTableWidget *m_table;
    QLabel *m_titleLabel;
    uint32_t m_previousRegisters[33]; // 32 registers + PC
    bool m_firstUpdate;
};

#endif // REGISTER_VIEW_H

