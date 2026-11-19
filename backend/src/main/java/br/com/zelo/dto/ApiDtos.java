package br.com.zelo.dto;

import jakarta.validation.constraints.*;
import java.time.LocalDateTime;

public final class ApiDtos {
    private ApiDtos() {}
    public record RegisterRequest(@NotBlank String nome, @Email @NotBlank String email, @Size(min=8) String senha) {}
    public record LoginRequest(@Email @NotBlank String email, @NotBlank String senha) {}
    public record AuthResponse(String token, Long idUsuario, String nome, String email) {}
    public record UsuarioResponse(Long id, String nome, String email) {}
    public record CategoriaResponse(Long id, String nome, String descricao) {}
    public record CriarOcorrenciaRequest(@NotNull Long idUsuario, @NotNull Long idCategoria,
        @NotBlank String titulo, @NotBlank String descricao,
        @NotNull @DecimalMin("-90.0") @DecimalMax("90.0") Double latitude,
        @NotNull @DecimalMin("-180.0") @DecimalMax("180.0") Double longitude, String endereco) {}
    public record OcorrenciaCriadaResponse(Long idOcorrencia, String protocolo, String mensagem) {}
    public record AlterarStatusRequest(@NotNull Long idUsuario, @NotBlank String novoStatus, String observacao) {}
    public record FotoRequest(@NotBlank String urlFoto) {}
    public record ApoioRequest(@NotNull Long idUsuario, @NotBlank String tipoApoio) {}
    public record MensagemResponse(String mensagem) {}
    public record OcorrenciaResumo(Long id, Long idUsuario, Long idCategoria, String titulo, String descricao,
        Double latitude, Double longitude, String endereco, String protocolo, String statusAtual, LocalDateTime dataAbertura) {}
}
