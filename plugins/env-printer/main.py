import os

def main():
    print("Hello from env-printer!")
    
    for key, value in os.environ.items():
        print(f"{key}={value}")

    print("Press any key to exit...")
    input()

if __name__ == "__main__":
    main()
