def matrix_multiply_3x3_3x1(matrix_3x3, matrix_3x1):
    # Check the dimensions
    if len(matrix_3x3) != 3 or len(matrix_3x3[0]) != 3:
        raise ValueError("The first matrix must be 3x3.")
    if len(matrix_3x1) != 3 or len(matrix_3x1[0]) != 1:
        raise ValueError("The second matrix must be 3x1.")
    
    # Initialize the result as a 3x1 matrix
    result = [[0] for _ in range(3)]
    
    # Perform the multiplication
    for i in range(3):
        for j in range(3):
            result[i][0] += matrix_3x3[i][j] * matrix_3x1[j][0]
    
    return result

def matrix_add_3x1(matrix_a, matrix_b):
    # Check the dimensions
    if len(matrix_a) != 3 or len(matrix_a[0]) != 1:
        raise ValueError("The first matrix must be 3x1.")
    if len(matrix_b) != 3 or len(matrix_b[0]) != 1:
        raise ValueError("The second matrix must be 3x1.")
    
    # Initialize the result matrix
    result = [[0] for _ in range(3)]
    
    # Perform the addition
    for i in range(3):
        result[i][0] = matrix_a[i][0] + matrix_b[i][0]
    
    return result

# Example usage
U=[[2.61, 1.56, 2.27],
    [0.82, 2.36, 0.17],
    [2.63, 2.16, 1.56]]

W=[[0.56, 2.27, 0.74],
    [1.80, 0.54, 2.03],
    [2.42, 0.20, 0.97]]

V=[[2.50, 0.63, 0.77],
    [0.97, 0.66, 2.84],
    [2.46, 1.91, 0.76]]

X1=[[0.29],
    [1.23],
    [1.37]]

X2=[[0.08],
    [1.10],
    [1.43]]

X3=[[1.64],
    [2.92],
    [2.24]]

h_0=[[1.22],
    [0.13],
    [2.56]]

h_1 = matrix_add_3x1(matrix_multiply_3x3_3x1(U,X1),matrix_multiply_3x3_3x1(W,h_0))
y_1=matrix_multiply_3x3_3x1(V,h_1) #已確認正確

h_2 = matrix_add_3x1(matrix_multiply_3x3_3x1(U,X2),matrix_multiply_3x3_3x1(W,h_1))
y_2=matrix_multiply_3x3_3x1(V,h_2)

h_3 = matrix_add_3x1(matrix_multiply_3x3_3x1(U,X3),matrix_multiply_3x3_3x1(W,h_2))
y_3=matrix_multiply_3x3_3x1(V,h_3)

result=matrix_multiply_3x3_3x1(U,X1)

print("h1: ")
for i in range(len(result)):
    print(h_1[i])
    print(" \n")
    
print("h2: ")
for i in range(len(result)):
    print(h_2[i])
    print(" \n")

print("h3: ")
for i in range(len(result)):
    print(h_3[i])
    print(" \n")

print("y1: ")
for i in range(len(y_1)):
    print(y_1[i])
    print(" \n")

print("y2: ")
for i in range(len(y_2)):
    print(y_2[i])
    print(" \n")
    
print("y3: ")
for i in range(len(y_3)):
    print(y_3[i])
    print(" \n")

