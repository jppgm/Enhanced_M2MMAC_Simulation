#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/mobility-module.h"
#include "ns3/config-store-module.h"
#include "ns3/wifi-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <stdio.h>
#include <stdbool.h>

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("comm-xnodes-antenna");

/*
The initial functions are for debugging. DataFailed is to count the number of DATA Packet transmission failure.
Some parts of the code are not commented because they already are in the ATIM window code
*/

static void
PhyTxBegin (std::string context, Ptr<const Packet> p)
{
  uint8_t adTo[6], adFrom[6];
  WifiMacHeader hdr;
  p->PeekHeader(hdr);
  hdr.GetAddr1().CopyTo(adTo); //ID do destinatario do pacote
  hdr.GetAddr2().CopyTo(adFrom); //ID do destinatario do pacote
  NS_LOG_UNCOND (context << " sending a packet --  From: " << adFrom[5]+0 <<  " To: " << adTo[5]+0 << " " << Simulator::Now ().GetSeconds () );
}

static void
DataFailed (std::string context, Mac48Address value)
{
  NS_LOG_UNCOND (context << "COLISION, a data transmission has failed " << Simulator::Now ().GetSeconds () );
}

/*static void
PhyRxEnd (std::string context, Ptr<const Packet> p)
{
  NS_LOG_UNCOND (context << " nó recebeu um pacote "<< Simulator::Now ().GetSeconds () );
}*/

int main (int argc, char *argv[])
{   
  std::string phyMode ("VhtMcs2");
  double rss = -80;  // -dBm
  double interval = 0.00001; // seconds
  bool verbose = false;
  uint16_t nStas = 40;
  uint16_t nRuns = 5;
  uint16_t maxPacketCount = 50000;
  uint16_t maxPacketSize = 512-24-34-28;
  uint16_t M = 25;
  uint16_t B = 5;
  uint16_t nSched = 6;
  double simStart = 1.00;
  double simEnd = 1.06;


  CommandLine cmd;

  cmd.AddValue ("phyMode", "Wifi Phy mode", phyMode);
  cmd.AddValue ("rss", "received signal strength", rss);
  cmd.AddValue ("interval", "interval (seconds) between packets", interval);
  cmd.AddValue ("verbose", "turn on all WifiNetDevice log components", verbose); 
  cmd.AddValue ("nStas", "Number of Stations", nStas);
  cmd.AddValue ("nRuns", "Number of Simulation Run", nRuns);
  cmd.AddValue ("M", "Number of Available Channels", M);
  cmd.AddValue ("B", "Number of Available Reception Antennas", B);
  cmd.AddValue ("nSched", "Number of Scheduled Streams", nSched);
  cmd.AddValue ("simStart", "Simulation Start", simStart);
  cmd.AddValue ("simEnd", "Simulation End", simEnd);
  

  cmd.Parse (argc, argv);
  // Convert to time object
  Time interPacketInterval = Seconds (interval);
  //the next instructions are used to get the ATIM window information, like who negotiated and which channel
  //they reserved. These information are stored in a matrix and an array.
  int result;
  int u;
  int w, p, g, k;
  int matrix[nStas+1][nStas+1] = {0};
  int channels[nStas+1] = {0};
  FILE *file = fopen("handshakefile.out",  "r");
  if (file != NULL) 
  {
    do {  //When a station detect that another node reserved the same channel, its row and column in the matrix are cleaned to cancel all the negotiations
      while ((result = fscanf(file, "SAMECHANNEL CANCEL 00:00:00:00:00:%x ", &u)) == 1) 
      {
        for (w = 1; w < nStas+1;w++) 
        {
          matrix[u][w] = 0;
          matrix[w][u] = 0;
        }
      } //After detecting that another node reserved the same channel, the NACKSHAKE says that the modified channel was understood by the receiver. So, the negotiation is considered set up once again
      while ((result = fscanf(file, "NACKSHAKE from 00:00:00:00:00:%x to 00:00:00:00:00:%x OK channel code %d channel code TX %d ", &w, &p, &g, &k)) == 4) 
      {
        matrix[w][p] = 1;
        channels[p] = g;
        channels[w] = k;
      }
      while ((result = fscanf(file, "HANDSHAKE from 00:00:00:00:00:%x to 00:00:00:00:00:%x OK channel code %d channel code TX %d ", &w, &p, &g, &k)) == 4) 
      { //This is just the normal handshake
        matrix[w][p] = 1;
        channels[p] = g;
        channels[w] = k;
      }
    } while (result != EOF);
    fclose(file);
  }
  else
  {
    NS_LOG_UNCOND ("FILE FAILED");
  }
  //for debugging purpose, in some situations a NACKSHAKE and a HANDSHAKE (like when sending a ATIMNACK
  //as ATIMACK) are printed. In these scenarios, the matrix can have 1 in one specific row/column and in its image
  //here we clean that
  for (w = 1; w<nStas+1;w++) 
  {
    for (p = 1; p<nStas+1;p++)
    {
      if (matrix[w][p] == matrix[p][w] && matrix[w][p] == 1)
      {
        matrix[p][w] = 0;
      }
    }
  }


  for (w = 1; w<nStas+1;w++)
  {
    for (p = 1; p<nStas+1;p++)
    {
      printf("%d ", matrix[w][p]);
    }
    printf("\n");
  }
    printf("\n");

  for (g = 1; g<nStas+1;g++)
  {
    printf("%d ", channels[g]);
  }
  printf("\n");

  Config::SetDefault ("ns3::WifiRemoteStationManager::FragmentationThreshold", StringValue ("2200"));
  Config::SetDefault ("ns3::WifiRemoteStationManager::RtsCtsThreshold", StringValue ("2000"));
  Config::SetDefault ("ns3::WifiRemoteStationManager::MaxSsrc", StringValue ("3"));
  Config::SetDefault ("ns3::WifiRemoteStationManager::IsAtimWindow",BooleanValue(false));
   Config::SetDefault ("ns3::WifiPhy::IsAtimWindow",BooleanValue(false));//not an ATIM window behavior
     Config::SetDefault ("ns3::RegularWifiMac::IsAtimWindow",BooleanValue(false));
  
  
  ns3::RngSeedManager::SetRun(nRuns); 
  
  NodeContainer c;
  c.Create (nStas);

  double min = 0.0;
  double max = 250.0;
  Ptr<UniformRandomVariable> x = CreateObject<UniformRandomVariable> ();
  x->SetAttribute ("Min", DoubleValue (min));
  x->SetAttribute ("Max", DoubleValue (max));
  MobilityHelper mobility;
  mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobility.SetPositionAllocator ("ns3::RandomRectanglePositionAllocator","X",PointerValue(x),"Y",PointerValue(x));
  mobility.Install (c);

  
  //Pilha TCP/IP 
  InternetStackHelper internet;
  internet.Install (c);
  
  //WifiNetDevice Helper
  WifiHelper wifi; 
  wifi.SetStandard (WIFI_PHY_STANDARD_80211b);    
  wifi.SetRemoteStationManager ("ns3::ConstantRateWifiManager",
                                "DataMode",StringValue (phyMode),
                                "ControlMode",StringValue (phyMode));
  
  //NetDevice PHY Helper 
  YansWifiPhyHelper wifiPhy =  YansWifiPhyHelper::Default (); 
  //wifiPhy.Set ("ShortPlcpPreambleSupported", BooleanValue(true) );  
  wifiPhy.SetPcapDataLinkType (YansWifiPhyHelper::DLT_IEEE802_11_RADIO);
  wifiPhy.Set ("RxGain", DoubleValue (1)); 
  wifiPhy.Set ("TxPowerEnd", DoubleValue  (16) );
  wifiPhy.Set ("TxPowerStart", DoubleValue(16) ); 
  wifiPhy.Set ("TxPowerLevels", UintegerValue(1) ); 
  wifiPhy.Set ("TxGain", DoubleValue(1));
  wifiPhy.Set ("Frequency", UintegerValue(5180)); //here we set the PHY frequency
  wifiPhy.Set ("ChannelWidth", UintegerValue(20));
  wifiPhy.Set ("EnergyDetectionThreshold",DoubleValue(-96));
  wifiPhy.Set ("RxNoiseFigure", DoubleValue(7));
  wifiPhy.Set ("TxAntennas", UintegerValue(1));
  wifiPhy.Set ("RxAntennas", UintegerValue(5));
  wifiPhy.Set ("ShortGuardEnabled", BooleanValue(true));
   
  //NetDevice MAC Helper
  WifiMacHelper wifiMac;
  wifiMac.SetType ("ns3::AdhocWifiMac");
  

  YansWifiChannelHelper wifiChannel[M];
  //despite the PHY frequency is set to 5.18 GHz, we consider the different channels by setting
  //the actual channel center frequency in the Friis model
  for (int h = 0; h < M; h++)
  {
    wifiChannel[h].SetPropagationDelay ("ns3::ConstantSpeedPropagationDelayModel");
    //wifiChannel[h].AddPropagationLoss ("ns3::FixedRssLossModel","Rss",DoubleValue (-20));
    //wifiChannel[h].AddPropagationLoss ("ns3::FixedRssLossModel","Rss",DoubleValue (rss));
    wifiChannel[h].AddPropagationLoss ("ns3::NakagamiPropagationLossModel");
    if (h < 8)
    {
      wifiChannel[h].AddPropagationLoss ("ns3::FriisPropagationLossModel","MinLoss",DoubleValue (5),
                                               "Frequency", DoubleValue(5.18e+09 + (0.02e+09)*h));
    }
    else if (h < 20)
    {
      wifiChannel[h].AddPropagationLoss ("ns3::FriisPropagationLossModel","MinLoss",DoubleValue (5),
                                               "Frequency", DoubleValue(5.340e+09 + (0.02e+09)*h));
    }
    else
    {
      wifiChannel[h].AddPropagationLoss ("ns3::FriisPropagationLossModel","MinLoss",DoubleValue (5),
                                               "Frequency", DoubleValue(5.345e+09 + (0.02e+09)*h));
    }
  }
  wifiPhy.SetErrorRateModel("ns3::NistErrorRateModel");
  //here we create two channels for each negotiation and set the communication between the nodes
  int i;
  int j;
  int counter = 0;
  for (i = 1; i < nStas+1; i++)
  {
    for (j = 1; j < nStas+1; j++)
    {
        if (matrix[i][j] == 0)
        {
          continue;
        }
        counter++; //debugging puporse
        printf("counter: %d\n", counter);
        wifiPhy.SetChannel (wifiChannel[channels[j]-1].Create ()); //Cria um canal zerado

        NodeContainer nodes;
            nodes.Add(c.Get(i-1)); //cliente primeiro
            nodes.Add(c.Get(j-1)); //servidor depois
        
        //INSTALACAO i CLIENTE j SERVIDOR    
        NetDeviceContainer netDevices = wifi.Install (wifiPhy, wifiMac, nodes); //Crio um NetDevice em cada
        
        //IP Address Helper
        Ipv4AddressHelper ipv4;
        ipv4.SetBase (("10." + std::to_string(i) + "." + std::to_string(j) + ".0").c_str(), "255.255.255.0"); //Configuro o IP da rede 10.i.j.0
        Ipv4InterfaceContainer iP = ipv4.Assign (netDevices);//Atribuo os IPs aos NetDevices
        
        //Servidor Udp
        uint16_t port;        
        port = 1000+10*i+j; // configuro a porta como 10ij
        UdpServerHelper server (port);
        server.SetAttribute("Port",UintegerValue (port));
        ApplicationContainer apps = server.Install (c.Get(j-1));
        apps.Start (Seconds (simStart));
        apps.Stop (Seconds (simEnd));
        
        //Cliente UdpClient
        UdpClientHelper client(iP.GetAddress(1), port);
        client.SetAttribute ("MaxPackets", UintegerValue (maxPacketCount));
        client.SetAttribute ("Interval", TimeValue (interPacketInterval));
        client.SetAttribute ("PacketSize", UintegerValue (maxPacketSize));
        client.SetAttribute("RemoteAddress", AddressValue(iP.GetAddress (1))); // iP (0) eh o cliente iP(1) eh o servidor
        client.SetAttribute("RemotePort", UintegerValue(port));
        apps = client.Install (c.Get (i-1));
        apps.Start (Seconds (simStart));
        apps.Stop (Seconds (simEnd));  
        
        //INSTALACAO j CLIENTE i servidor
        NodeContainer nodes2;
            nodes2.Add(c.Get(j-1)); //cliente primeiro
            nodes2.Add(c.Get(i-1)); //servidor depois


        wifiPhy.SetChannel (wifiChannel[channels[i]-1].Create ()); //Cria um canal zerado
        NetDeviceContainer netDevices2 = wifi.Install (wifiPhy, wifiMac, nodes2); //Crio um NetDevice em cada

        //IP Address Helper
        ipv4.SetBase (("10." + std::to_string(j) + "." + std::to_string(i) + ".0").c_str(), "255.255.255.0"); //Configuro o IP da rede 10.j.i.0
        Ipv4InterfaceContainer iP2 = ipv4.Assign (netDevices2);//Atribuo os IPs aos NetDevices
        
        //Servidor Udp
        port = 1000+10*j+i; // configuro a porta como 10ij
        UdpServerHelper server2 (port);
        server2.SetAttribute("Port",UintegerValue (port));
        apps = server2.Install (c.Get(i-1));
        apps.Start (Seconds (simStart));
        apps.Stop (Seconds (simEnd));
        
        //Cliente UdpClient
        UdpClientHelper client2(iP2.GetAddress(1), port);
        client2.SetAttribute ("MaxPackets", UintegerValue (maxPacketCount));
        client2.SetAttribute ("Interval", TimeValue (interPacketInterval));
        client2.SetAttribute ("PacketSize", UintegerValue (maxPacketSize));
        client2.SetAttribute("RemoteAddress", AddressValue(iP2.GetAddress (1)));
        client2.SetAttribute("RemotePort", UintegerValue(port));
        apps = client2.Install (c.Get (j-1));
        apps.Start (Seconds (simStart));
        apps.Stop (Seconds (simEnd)); 
        NS_LOG_UNCOND ("Streams entre i= " << i << " e j= " << j << " estabelecidos COM SUCESSO."); 
        NS_LOG_UNCOND (" ");
    }
  }
  
  Config::Connect ("/NodeList/*/DeviceList/*/RemoteStationManager/MacTxDataFailed", MakeCallback (&DataFailed));
  Config::Connect ("/NodeList/*/DeviceList/*/Phy/PhyTxBegin", MakeCallback (&PhyTxBegin));
  //Config::Connect ("/NodeList/*/DeviceList/*/Phy/PhyRxEnd", MakeCallback (&PhyRxEnd));

  ArpCache a;
  a.PopulateArpCache ();
  wifiPhy.EnablePcapAll ("comm-xnodes-antenna");
  
  Simulator::Stop (Seconds (simEnd));
  Simulator::Run ();   
  Simulator::Destroy ();
  return 0;
}


