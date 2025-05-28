#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <papi.h>
#include <cuda_runtime.h>
#define hl_region_begin(A) retval = PAPI_hl_region_begin(A); \
        if ( retval != PAPI_OK ) handle_error(retval);
#define hl_region_end(A) retval = PAPI_hl_region_end(A); \
        if ( retval != PAPI_OK ) handle_error(retval);
//nvcc MxM.cu -I/${PAPI_DIR}/include -L/${PAPI_DIR}/lib -o MxM -lpapi

//
#define BLOCK_SIZE 5
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

__global__ void Matriz_Matriz_kernel(float* x, float* y, float* z, int size) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    float num = 0.;
    if (i < size && j < size) {
        for (int k = 0; k < size; k++) {
            num += x[i*size+k] * y [k*size+j];
        }
        z[i*size+j] = num;
    }
}

void CUDA_CHECK(cudaError_t err) {
    if (err != cudaSuccess) {
        printf("%s in %s at line %d \n", cudaGetErrorString(err), __FILE__, __LINE__);
        exit(1);
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
    float* cudaA;
    float* cudaB;
    float* cudaC;
    int arr_size = n*n*sizeof(float);
    cudaError_t err = cudaMalloc((void**)&cudaA, arr_size);
    CUDA_CHECK(err);
    cudaMalloc((void**)&cudaB, arr_size);
    CUDA_CHECK(err);
    cudaMalloc((void**)&cudaC, arr_size);
    CUDA_CHECK(err);
    cudaMemcpy(cudaA, A, arr_size, cudaMemcpyHostToDevice);
    CUDA_CHECK(err);
    cudaMemcpy(cudaB, B, arr_size, cudaMemcpyHostToDevice);
    CUDA_CHECK(err);
    cudaMemcpy(cudaC, C, arr_size, cudaMemcpyHostToDevice);
    CUDA_CHECK(err);
    dim3 dim_block(BLOCK_SIZE, BLOCK_SIZE, 1);
    dim3 dim_grid(ceil(n/BLOCK_SIZE), ceil(n/BLOCK_SIZE), 1);
    Imprimir_Inicio(A, B, n);
    hl_region_end("initialization");
    
    hl_region_begin("computation");
    for (int i = 0; i < Niter; i++) {
        Matriz_Matriz_kernel<<<dim_grid, dim_block>>> (cudaA, cudaB, cudaC, n);
        cudaDeviceSynchronize();
    }
    hl_region_end("computation");
    
    hl_region_begin("end");
    cudaMemcpy(C, cudaC, arr_size, cudaMemcpyDeviceToHost);
    CUDA_CHECK(err);
    cudaFree(cudaA);
    cudaFree(cudaB);
    cudaFree(cudaC);
    Imprimir_Resultados(C, n, Niter);
    hl_region_end("end");
    
    hl_region_end("program");
}