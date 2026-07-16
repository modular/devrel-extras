trait Percentable:
    def percentage(self) -> Float64:
        ...

@fieldwise_init
struct HealthBar(Copyable, Percentable):
    var current: Float64
    var max: Float64

    def percentage(self) -> Float64:
        return self.current / self.max * 100

@fieldwise_init
struct ManaPool(Copyable, Percentable):
    var mana: Float64
    var capacity: Float64

    def percentage(self) -> Float64:
        return self.mana / self.capacity * 100

def report[T: Percentable](item:T):
    print(item.percentage(), "%")

def main():
    report(HealthBar(30.0, 120.0))    # 25.0 %
    report(ManaPool(45.0, 50.0))      # 90.0 %