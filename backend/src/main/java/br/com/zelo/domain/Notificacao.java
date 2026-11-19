package br.com.zelo.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "NOTIFICACAO")
public class Notificacao {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "ID_NOTIFICACAO")
    private Long id;
    @Column(name = "ID_USUARIO", nullable = false) private Long idUsuario;
    @Column(name = "ID_OCORRENCIA") private Long idOcorrencia;
    @Column(name = "TITULO", nullable = false) private String titulo;
    @Column(name = "MENSAGEM", nullable = false) private String mensagem;
    @Column(name = "LIDA") private String lida;
    @Column(name = "DATA_ENVIO") private LocalDateTime dataEnvio;
    public Long getId(){return id;} public Long getIdUsuario(){return idUsuario;}
    public Long getIdOcorrencia(){return idOcorrencia;} public String getTitulo(){return titulo;}
    public String getMensagem(){return mensagem;} public String getLida(){return lida;}
    public LocalDateTime getDataEnvio(){return dataEnvio;} public void setLida(String v){lida=v;}
}
