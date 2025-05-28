#include <stdio.h>
#include <stdlib.h>
#include <papi.h>
#define hl_region_begin(A) retval = PAPI_hl_region_begin(A); \
        if ( retval != PAPI_OK ) handle_error(retval);
#define hl_region_end(A) retval = PAPI_hl_region_end(A); \
        if ( retval != PAPI_OK ) handle_error(retval);
//gcc MxM.c -I/${PAPI_DIR}/include -L/${PAPI_DIR}/lib -o MxM -lpapi

//Matrices nxn
#define n 250
float A[n*n];
float B[n*n];
float C[n*n]; // C = A*B
//Iteraciones a repetir el programa
int Niter = 10000;

void Inicializar_Matrices(float* x, float* y, float* z, int size) {
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float num = (float) (i+j);
            x[i*size+j] = num;
            y[i*size+j] = num;
            z[i*size+j] = 0.;
        }
    }
}

void Imprimir_Matriz(float* m, int size) {
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            printf("%f\t", m[i*size+j]);
        }
        printf("\n");
    }
    printf("\n");
}

void Imprimir_Inicio(float* x, float* y, int size) {
    printf("#################################\n");
    printf("# PROGRAMA MATRIZ x MATRIZ BASE #\n");
    printf("#################################\n\n");
    printf("LA MATRIZ A ES:\n");
    Imprimir_Matriz(x, size);
    printf("LA MATRIZ B ES:\n");
    Imprimir_Matriz(x, size);
    printf("\nCOMIENZA LA EJECUCION\n");
}

void Imprimir_Resultados(float* z, int size, int iters) {
    printf("EJECUCION TERMINADA\n");
    printf("LA MATRIZ RESULTANTE C ES:\n");
    Imprimir_Matriz(z, size);
    printf("SE HAN REALIZADO %d ITERACIONES.\n", iters);
}

void Matriz_Matriz(float* x, float* y, float* z, int size) {
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float num = 0.;
            for (int k = 0; k < size; k++) {
                num += x[i*size+k] * y [k*size+j];
            }
            z[i*size+j] = num;
        }
    }
}

void handle_error(int retval) {
    printf("PAPI error %d: %s\n", retval, PAPI_strerror(retval));
    exit(1);
}

int main() {
    int retval;
    hl_region_begin("program");
    
    hl_region_begin("initialization");
    Inicializar_Matrices(A, B, C, n);
    Imprimir_Inicio(A, B, n);
    hl_region_end("initialization");
    
    hl_region_begin("computation");
    for (int i = 0; i < Niter; i++) {
        Matriz_Matriz(A, B, C, n);
    }
    hl_region_end("computation");
    
    hl_region_begin("end");
    Imprimir_Resultados(C, n, Niter);
    hl_region_end("end");
    
    hl_region_end("program");
}