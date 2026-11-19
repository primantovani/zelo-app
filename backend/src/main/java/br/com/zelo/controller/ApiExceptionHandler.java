package br.com.zelo.controller;

import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<?> badRequest(IllegalArgumentException e){return ResponseEntity.badRequest().body(Map.of("erro",e.getMessage()));}
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<?> validation(MethodArgumentNotValidException e){
        String msg=e.getBindingResult().getFieldErrors().stream().map(x->x.getField()+": "+x.getDefaultMessage()).findFirst().orElse("Dados inválidos.");
        return ResponseEntity.badRequest().body(Map.of("erro",msg));
    }
    @ExceptionHandler(Exception.class)
    ResponseEntity<?> generic(Exception e){return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("erro","Erro interno ao processar a solicitação."));}
}
