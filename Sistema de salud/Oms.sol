// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract Oms_covid {

    //Direccion de la OMS
    address public OMS;

    constructor (){
        OMS = msg.sender;
    }

    //Mapping para relacionar los centros de salud 
    mapping (address => bool) public validacionCentrosSalud;

    //Relacionar una direccion con un centro de salud de su contrato
    mapping (address => address) public centroSaludContrato;

    //Array de direcciones que almacene los contractos validos
    address [] direccionesContratosSalud;

    //Array de las direcciones que solicitan
    address [] solicitudes;

    //Eventos
    event nuevoCentroValidoEvent (address);
    event nuevoContratoEvent (address, address);
    event solicitudAccesoEvent (address);

    //Modificador que solo puede validar el admin
    modifier onlyOMS(address _direccion){
        require (_direccion == OMS, "No tienes permisos para esta operacion");
        _;
    }

    //Funcion para validar nuevos centros de salud
    function validarCentrosSalud (address _centroSalud) public onlyOMS(msg.sender){
        //Asignacion del estado de valudez al centro de salud
        validacionCentrosSalud [_centroSalud] = true;
        
        emit nuevoCentroValidoEvent(_centroSalud);
    }

    //Funcion que permite crar un contrato inteligente de un centro de salud
    function factoryCentroSalud () public {
        //Filtrando para que unicamente los centros validos puedan crear un contrato
        require (validacionCentrosSalud[msg.sender] == true, "No tienes permisos para ejecutar esta funcion");

        //Generar un smart contract
        address contratoCentroSalud = address (new CentroSalud(msg.sender));

        //Almacenamiento de la direccion del contrato en el array
        direccionesContratosSalud.push(contratoCentroSalud);

        //Relacion entre el centro de su salud y su contrato 
        centroSaludContrato[msg.sender] =  contratoCentroSalud;

        emit nuevoContratoEvent(contratoCentroSalud , msg.sender);
    }

    //funcion para solicitar acceso al sistema medico
    function solitarAcceso () public {
        //Almacenar la direccion en el array de solicitudes
        solicitudes.push(msg.sender);

        emit solicitudAccesoEvent(msg.sender);
    }

    //Funcion que visualiza las direcciones que han solicitado acceos al sistema medico
    function visualizarSolicitudes () public view onlyOMS(msg.sender) returns  (address [] memory) {
        return solicitudes;
    }

}


contract CentroSalud {

    address public direccionCentroSalud;
    address public direccionContrato;

    constructor (address _direccion) {
        direccionCentroSalud = _direccion;
        direccionContrato = address(this);
    }

    //Estructura de resultados
    struct resultados {
        bool diagnostico;
        string codigoIPFS;
    }

    //Mapping para relacionar el hash de las personas con su resultado
    mapping (bytes32 => resultados) resultadosCOVID;

    //Events
    event nuevoResultadoEvent (bool, string);

    //Filtro solo puede el centro de salud
    modifier onlyCentroSalud (address _direccion){
        require (_direccion == direccionCentroSalud, "No tienes permiso para ejecutar esta funcion");
        _;
    }

    //Funcion para emitir un resultado de una prueba COVID
    function resultadosPruebaCovid (string memory _idPersona, bool _resultadoCovid, string memory _codigoIPFS) 
    public onlyCentroSalud(msg.sender){
        //hash de la identificacion de la pesona
        bytes32 hashIdPersona =  keccak256 (abi.encodePacked(_idPersona));

        //Relacion del hash de la persona con la estructura de resultado
        resultadosCOVID [ hashIdPersona] =  resultados(_resultadoCovid , _codigoIPFS);

        emit nuevoResultadoEvent(_resultadoCovid , _codigoIPFS);
    }

    //Funcion que permite la visualizacion de los resultados
    function visualizarResultados (string memory _idPersona) public view 
        returns (string memory _resultadoPrueba, string memory _codigoIPFS){
            //Hash de la identidad de la persona 
            bytes32 hashIdPersona =  keccak256 (abi.encodePacked(_idPersona));

            //Retorno de un boleano con un string
            string memory resultadoPrueba;
            if (resultadosCOVID[hashIdPersona]. diagnostico == true){
                resultadoPrueba = "Positivo";
            }else {
                resultadoPrueba = "Negativo";
            }

            //Retornamos los parametros
            _resultadoPrueba = resultadoPrueba;
            _codigoIPFS = resultadosCOVID[hashIdPersona].codigoIPFS;
    }


}