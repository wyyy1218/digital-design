#ifndef CONTROL_PANEL_H
#define CONTROL_PANEL_H

#include <QWidget>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QPushButton>
#include <QSpinBox>
#include <QLabel>

class ControlPanel : public QWidget
{
    Q_OBJECT

public:
    explicit ControlPanel(QWidget *parent = nullptr);
    
    void setRunning(bool running);
    bool isRunning() const { return m_running; }

signals:
    void loadClicked();
    void runClicked();
    void pauseClicked();
    void stepClicked();
    void stepNClicked(int n);
    void resetClicked();

private slots:
    void onStepNValueChanged(int value);

private:
    QPushButton *m_loadButton;
    QPushButton *m_runButton;
    QPushButton *m_pauseButton;
    QPushButton *m_stepButton;
    QPushButton *m_resetButton;
    QSpinBox *m_stepNSpinBox;
    QPushButton *m_stepNButton;
    
    bool m_running;
};

#endif // CONTROL_PANEL_H

