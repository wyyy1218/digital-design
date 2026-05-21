#include "main_window.h"
#include <QApplication>
#include <QStyleFactory>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    // Set application properties
    app.setApplicationName("TEMU");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("LoongArch32");
    
    // Create and show main window
    MainWindow window;
    window.show();
    window.raise();  // Bring window to front
    window.activateWindow();  // Activate window
    
    // Print helpful message to console
    const char* display = getenv("DISPLAY");
    printf("\n");
    printf("========================================\n");
    printf("TEMU GUI 已启动\n");
    printf("========================================\n");
    printf("DISPLAY = %s\n", display ? display : "(未设置)");
    printf("如果看不到图形窗口，请运行: ./gui/start_gui.sh\n");
    printf("或设置DISPLAY: export DISPLAY=:0 && ./gui/temu_gui\n");
    printf("========================================\n");
    printf("\n");
    
    return app.exec();
}

