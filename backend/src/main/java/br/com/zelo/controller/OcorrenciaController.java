package br.com.zelo.controller;
import br.com.zelo.dto.ApiDtos.*;
import br.com.zelo.service.OcorrenciaService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/ocorrencias")
public class OcorrenciaController {
    private final OcorrenciaService s; public OcorrenciaController(OcorrenciaService s){this.s=s;}
    @GetMapping public Object listar(){return s.listar();}
    @GetMapping("/{id}") public Object buscar(@PathVariable Long id){return s.buscar(id);}
    @GetMapping("/protocolo/{protocolo}") public Object protocolo(@PathVariable String protocolo){return s.porProtocolo(protocolo);}
    @GetMapping("/usuario/{idUsuario}") public Object minhas(@PathVariable Long idUsuario){return s.minhas(idUsuario);}
    @PostMapping public OcorrenciaCriadaResponse criar(@Valid @RequestBody CriarOcorrenciaRequest r){return s.criar(r);}
    @PatchMapping("/{id}/status") public MensagemResponse status(@PathVariable Long id,@Valid @RequestBody AlterarStatusRequest r){s.alterarStatus(id,r);return new MensagemResponse("Status atualizado; histórico e notificação registrados.");}
    @GetMapping("/{id}/fotos") public Object fotos(@PathVariable Long id){return s.listarFotos(id);}
    @PostMapping("/{id}/fotos") public Object foto(@PathVariable Long id,@Valid @RequestBody FotoRequest r){return s.adicionarFoto(id,r);}
    @GetMapping("/{id}/apoios") public Object apoios(@PathVariable Long id){return s.listarApoios(id);}
    @PostMapping("/{id}/apoios") public Object apoiar(@PathVariable Long id,@Valid @RequestBody ApoioRequest r){return s.apoiar(id,r);}
}
