import numpy as np
import struct

map = {}

class randomData:

    def getRND(self, cmd, size, client_id, count):
        values = (cmd, size)
        packer = struct.Struct('I I')
        st = packer.pack(*values)
        data = bytearray(st)

        arr = []
        key = "_id_" + client_id + str(count)

        try:
            arr = map[key]
            for item in arr:
                data.append(item)
            del map[key]
            print( "using random numbers for key " + key)

        except:
            arr = np.random.random_integers(low=0, high=255, size=(size,))
            map[key] = arr
            for item in arr:
                data.append(item)
            print( "generating new random numbers for key " + key)

        return data

if __name__ == '__main__':
    t = randomData()
    d1 = t.getRND(10013, 50000, "1234")
    d2 = t.getRND(10013, 50000, "1235")
    d3 = t.getRND(10013, 50000, "1234")
    d4 = t.getRND(10013, 50000, "1235")
    d5 = t.getRND(10013, 50000, "1234")
