import random

alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
upperalphabet = alphabet.upper()

def pin_gen(pw_len):
    pwlist = []

    for i in range(pw_len//3):
        pwlist.append(alphabet[random.randrange(len(alphabet))])
        pwlist.append(upperalphabet[random.randrange(len(upperalphabet))])
        pwlist.append(str(random.randrange(10)))
    for i in range(pw_len-len(pwlist)):
        pwlist.append(alphabet[random.randrange(len(alphabet))])

    random.shuffle(pwlist)
    pwstring = "".join(pwlist)
    return pwstring


if __name__ == '__main__':
    pwstring = pin_gen(6)
    print(pwstring)

