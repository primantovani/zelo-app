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
    // Regras de negocio do PL/SQL (RAISE_APPLICATION_ERROR -20000 a -20999) viram 400 com a mensagem da procedure.
    @ExceptionHandler(org.springframework.dao.DataAccessException.class)
    ResponseEntity<?> regraDoBanco(org.springframework.dao.DataAccessException e){
        var m=java.util.regex.Pattern.compile("ORA-20\\d{3}: ([^\\n]+)").matcher(String.valueOf(e.getMostSpecificCause().getMessage()));
        if(m.find()) return ResponseEntity.badRequest().body(Map.of("erro",m.group(1).trim()));
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("erro","Erro interno ao processar a solicitação."));
    }
    @ExceptionHandler(Exception.class)
    ResponseEntity<?> generic(Exception e){return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("erro","Erro interno ao processar a solicitação."));}
}
