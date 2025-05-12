class HX711:
    def __init__(self, dout, pd_sck):
        import time
        from machine import Pin
        self.PD_SCK = pd_sck
        self.DOUT = dout

        self.PD_SCK.init(Pin.OUT)
        self.PD_SCK.value(0)

        self.DOUT.init(Pin.IN)
        self.reference_unit = 1

    def is_ready(self):
        return self.DOUT.value() == 0

    def read(self):
        while not self.is_ready():
            pass

        result = 0
        for i in range(24):
            self.PD_SCK.value(1)
            result = result << 1
            self.PD_SCK.value(0)
            if self.DOUT.value():
                result += 1

        self.PD_SCK.value(1)
        self.PD_SCK.value(0)

        if result & 0x800000:
            result |= ~0xffffff

        return result

    def read_average(self, times=3):
        sum = 0
        for _ in range(times):
            sum += self.read()
        return sum / times

    def set_reference_unit(self, ref_unit):
        self.reference_unit = ref_unit

    def get_weight(self, times=3):
        return self.read_average(times) / self.reference_unit

    def tare(self, times=15):
        self.offset = self.read_average(times)
