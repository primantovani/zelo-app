package br.com.zelo.controller;
import br.com.zelo.service.ConsultaService;
import org.springframework.web.bind.annotation.*;

@RestController
public class ConsultaController {
    private final ConsultaService s; public ConsultaController(ConsultaService s){this.s=s;}
    @GetMapping("/categorias") public Object categorias(){return s.categorias();}
    @GetMapping("/ocorrencias/{id}/historico") public Object historico(@PathVariable Long id){return s.historico(id);}
    @GetMapping("/usuarios/{idUsuario}/notificacoes") public Object notificacoes(@PathVariable Long idUsuario){return s.notificacoes(idUsuario);}
    @PatchMapping("/notificacoes/{id}/lida") public Object lida(@PathVariable Long id){return s.marcarLida(id);}
}
