#ifndef MAIN_WINDOW_H
#define MAIN_WINDOW_H

#include <QMainWindow>
#include <QMenuBar>
#include <QToolBar>
#include <QStatusBar>
#include <QSplitter>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QTimer>

class RegisterView;
class CodeView;
class MemoryView;
class ControlPanel;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void updateViews();
    void onLoadProgram();
    void onRun();
    void onPause();
    void onStep();
    void onStepN();
    void onReset();
    void onWatchpoints();
    void onEvaluateExpr();
    void onAbout();

private:
    void setupMenus();
    void setupToolbar();
    void setupStatusBar();
    void setupLayout();
    void setupConnections();
    void loadProgramFiles();

    // Menu actions
    QAction *m_loadAction;
    QAction *m_runAction;
    QAction *m_pauseAction;
    QAction *m_stepAction;
    QAction *m_stepNAction;
    QAction *m_resetAction;
    QAction *m_watchpointsAction;
    QAction *m_evalExprAction;
    QAction *m_exitAction;
    QAction *m_aboutAction;

    // Views
    RegisterView *m_registerView;
    CodeView *m_codeView;
    MemoryView *m_memoryView;
    ControlPanel *m_controlPanel;

    // Layout
    QSplitter *m_mainSplitter;
    QSplitter *m_rightSplitter;

    // Timer for periodic updates
    QTimer *m_updateTimer;

    // State
    bool m_programLoaded;
    int m_instructionCount;
};

#endif // MAIN_WINDOW_H

