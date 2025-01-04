#include <iostream>
#include <vector>

using namespace std;

class ExampleClass {
public:
  ExampleClass(int x) : m_x(x) {}
  void doSomething() { cout << "Value: " << m_x << endl; }

private:
  int m_x;
};

int main() {
  ExampleClass example(5);
  example.doSomething();

  // Unused variable
  int unused = 0;

  vector<int> v;
  for (int i = 0; i < 10; i++) {
    v.push_back(i);
  }

  return 0;
}
