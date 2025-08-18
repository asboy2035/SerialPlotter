// Serial monitor executable - CPP

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <string.h>
#include <errno.h>
#include <sys/select.h>

int main(int argc, char *argv[]) {
    if(argc < 2) {
        fprintf(stderr, "Usage: %s <device>\n", argv[0]);
        return 1;
    }

    // First, let's debug and find the Arduino port
    char port_path[256] = {0};

    printf("🔍 Searching for Arduino ports...\n");
    fflush(stdout);

    // List all available ports for debugging
    system("ls -la /dev/cu.* 2>/dev/null");

    // Try multiple common Arduino port patterns
    const char* port_patterns[] = {
        "ls /dev/cu.usbmodem* 2>/dev/null | head -1",
        "ls /dev/cu.usbserial* 2>/dev/null | head -1",
        "ls /dev/cu.wchusbserial* 2>/dev/null | head -1",
        "ls /dev/cu.SLAB_USBtoUART* 2>/dev/null | head -1"
    };

    bool found_port = false;
    for (int i = 0; i < 4; i++) {
        FILE *fp = popen(port_patterns[i], "r");
        if (fp != NULL) {
            if (fgets(port_path, sizeof(port_path), fp) != NULL) {
                // Remove newline
                port_path[strcspn(port_path, "\n")] = 0;
                if (strlen(port_path) > 0) {
                    printf("✅ Found Arduino port: %s\n", port_path);
                    found_port = true;
                    pclose(fp);
                    break;
                }
            }
            pclose(fp);
        }
    }

    if (!found_port) {
        printf("❌ No Arduino port found automatically\n");
        printf("Available ports:\n");
        system("ls /dev/cu.* 2>/dev/null");
        return 1;
    }

    // Open the serial port
    int serial_fd = open(port_path, O_RDONLY | O_NOCTTY | O_NONBLOCK);
    if (serial_fd < 0) {
        fprintf(stderr, "❌ Error opening %s: %s\n", port_path, strerror(errno));
        return 1;
    }

    // Configure the serial port
    struct termios tty;
    if (tcgetattr(serial_fd, &tty) != 0) {
        fprintf(stderr, "❌ Error getting serial attributes: %s\n", strerror(errno));
        close(serial_fd);
        return 1;
    }

    // Set baud rate to 9600 (common Arduino baud rate)
    cfsetospeed(&tty, B9600);
    cfsetispeed(&tty, B9600);

    // Configure for raw input
    tty.c_cflag &= ~PARENB;        // No parity
    tty.c_cflag &= ~CSTOPB;        // 1 stop bit
    tty.c_cflag &= ~CSIZE;         // Clear size bits
    tty.c_cflag |= CS8;            // 8 data bits
    tty.c_cflag &= ~CRTSCTS;       // No hardware flow control
    tty.c_cflag |= CREAD | CLOCAL; // Enable reading, ignore control lines

    tty.c_lflag &= ~ICANON;        // Raw input
    tty.c_lflag &= ~ECHO;          // No echo
    tty.c_lflag &= ~ECHOE;         // No echo erase
    tty.c_lflag &= ~ECHONL;        // No echo newline
    tty.c_lflag &= ~ISIG;          // No signal processing

    tty.c_iflag &= ~(IXON | IXOFF | IXANY); // No software flow control
    tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL);

    tty.c_oflag &= ~OPOST;         // Raw output

    // Set timeouts
    tty.c_cc[VTIME] = 1;           // 0.1 second timeout
    tty.c_cc[VMIN] = 0;            // Non-blocking read

    if (tcsetattr(serial_fd, TCSANOW, &tty) != 0) {
        fprintf(stderr, "❌ Error setting serial attributes: %s\n", strerror(errno));
        close(serial_fd);
        return 1;
    }

    printf("✅ Connected to %s at 9600 baud\n", port_path);
    printf("📊 Starting serial monitor (Ctrl+C to stop)...\n");
    fflush(stdout);

    // Read from serial port continuously
    char buffer[1024];
    fd_set read_fds;
    struct timeval timeout;

    while (1) {
        FD_ZERO(&read_fds);
        FD_SET(serial_fd, &read_fds);

        timeout.tv_sec = 1;
        timeout.tv_usec = 0;

        int result = select(serial_fd + 1, &read_fds, NULL, NULL, &timeout);

        if (result > 0 && FD_ISSET(serial_fd, &read_fds)) {
            ssize_t bytes_read = read(serial_fd, buffer, sizeof(buffer) - 1);
            if (bytes_read > 0) {
                buffer[bytes_read] = '\0';
                printf("%s", buffer);
                fflush(stdout);
            }
        }
    }

    close(serial_fd);
    return 0;
}
