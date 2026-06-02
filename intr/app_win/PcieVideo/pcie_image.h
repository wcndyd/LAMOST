#ifndef PCIE_IMAGE_DEMO_H
#define PCIE_IMAGE_DEMO_H
#include <QDebug>
#include <QThread>
#include <QMessageBox>
#include <QMainWindow>
#include "pcie_fun.h"

#if _MSC_VER >= 1600
#pragma execution_character_set("utf-8")
#endif

namespace Ui {
class MainWindow;
}

class event_thread0 : public QThread
{
    Q_OBJECT
public:
    bool isrun = false;
    event_thread0(){};
    void run(){
        isrun=true;
        while (isrun)
        {
            wait_event(0);
            emit sig_disp(0);
        }
    }
signals:
    void sig_disp(int id);
};

class event_thread1 : public QThread
{
    Q_OBJECT
public:
    bool isrun = false;
    event_thread1(){};
    void run(){
        isrun=true;
        while (isrun)
        {
            wait_event(1);
            emit sig_disp(1);
        }
    }
signals:
    void sig_disp(int id);
};

class event_thread2 : public QThread
{
    Q_OBJECT
public:
    bool isrun = false;
    event_thread2(){};
    void run(){
        isrun=true;
        while (isrun)
        {
            wait_event(2);
            emit sig_disp(2);
        }
    }
signals:
    void sig_disp(int id);
};

class event_thread3 : public QThread
{
    Q_OBJECT
public:
    bool isrun = false;
    event_thread3(){};
    void run(){
        isrun=true;
        while (isrun)
        {
            wait_event(3);
            emit sig_disp(3);
        }
    }
signals:
    void sig_disp(int id);
};

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

public:
    event_thread0 m_pcie_event_0;
    event_thread1 m_pcie_event_1;
    event_thread2 m_pcie_event_2;
    event_thread3 m_pcie_event_3;
    QImage *m_image;

private slots:
    void on_pushButton_clicked();
    void disp_slot(int id);
    void slotThreadFinish();
private:
    Ui::MainWindow *ui;
    int m_state=0;
};

#endif // MIZ7035_DEMO_H
