#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
	setWindowIcon(QIcon(":/mainwindow/logo.ico"));//ÉèÖÃ×´Ì¬À¸Í¼±ê
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}
