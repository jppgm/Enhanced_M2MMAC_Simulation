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

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("atimretry-v2019");

/*
These initial functions are mainly for debugging purpose. However, AtimFailed is used to
detect when the atimack is not received within a period.
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

/*static void
PhyRxEnd (std::string context, Ptr<const Packet> p)
{
  NS_LOG_UNCOND (context << " nó recebeu um pacote "<< Simulator::Now ().GetSeconds () );
}*/

static void
MacTx (std::string context, Ptr<const Packet> p)
{
  NS_LOG_UNCOND (context << " preparando pra transmitir mac "<<Simulator::Now ().GetSeconds () );
}

static void
PhyTxDrop (std::string context, Ptr<const Packet> p)
{
  NS_LOG_UNCOND (context << " nó dropou na camada fisica "<< Simulator::Now ().GetSeconds () );
}


static void
AtimFailed (std::string context, Mac48Address value)
{
  NS_LOG_UNCOND (context << "COLISION, An atim transmission has failed " << Simulator::Now ().GetSeconds () );
}


static void
MacTxDrop (std::string context, Ptr<const Packet> p)
{
  NS_LOG_UNCOND (context << " dropou pacote na mac "<< Simulator::Now ().GetSeconds () );
}

int main (int argc, char *argv[])
{
    
   
  std::string phyMode ("VhtMcs2");
  //double rss = -80;  // -dBm
  double interval = 0.00001; // seconds
  bool verbose = 1;
  uint16_t nStas = 5;
  uint16_t nRuns = 7;
  double timeSlot = 0.000009;

  CommandLine cmd;

  cmd.AddValue ("phyMode", "Wifi Phy mode", phyMode);
 // cmd.AddValue ("rss", "received signal strength", rss);
  cmd.AddValue ("interval", "interval (seconds) between packets", interval);
  cmd.AddValue ("verbose", "turn on all WifiNetDevice log components", verbose); 
  cmd.AddValue ("nStas", "Number of Stations", nStas);
  cmd.AddValue ("nRuns", "Number of Simulation Run", nRuns);
  cmd.AddValue ("timeSlot", "Time slot duration", timeSlot);
  
  cmd.Parse (argc, argv);
  // Convert to time object
  Time interPacketInterval = Seconds (interval);
  
  Config::SetDefault ("ns3::WifiRemoteStationManager::FragmentationThreshold", StringValue ("2200"));
  Config::SetDefault ("ns3::WifiRemoteStationManager::RtsCtsThreshold", StringValue ("2000"));
  Config::SetDefault ("ns3::WifiRemoteStationManager::MaxSsrc", StringValue ("3"));
  Config::SetDefault ("ns3::WifiRemoteStationManager::IsAtimWindow",BooleanValue(true)); 
  Config::SetDefault ("ns3::WifiPhy::IsAtimWindow",BooleanValue(true)); //to set the ATIM  window functional details
  Config::SetDefault ("ns3::RegularWifiMac::IsAtimWindow",BooleanValue(true));
  
  ns3::RngSeedManager::SetRun(nRuns);
  //ns3::RngSeedManager::SetSeed(nRuns);
  
  NodeContainer c;
  c.Create (nStas);
  //to set the nodes position
  double min = 0.0;
  double max = 250.0;
  Ptr<UniformRandomVariable> x = CreateObject<UniformRandomVariable> ();
  x->SetAttribute ("Min", DoubleValue (min));
  x->SetAttribute ("Max", DoubleValue (max));
  MobilityHelper mobility;
  mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobility.SetPositionAllocator ("ns3::RandomRectanglePositionAllocator","X",PointerValue(x),"Y",PointerValue(x));
  mobility.Install (c);

  WifiHelper wifi;

  if (verbose)
    {
    //LogComponentEnable ("YansWifiChannel", LOG_LEVEL_ALL);
    //LogComponentEnable ("MacLow", LOG_FUNCTION);
    //LogComponentEnable ("RegularWifiMac", LOG_LEVEL_ALL);
   // LogComponentEnable ("UdpClient", LOG_FUNCTION);
  }

  wifi.SetStandard (WIFI_PHY_STANDARD_80211b); 
  //to set the PHT parameters
  YansWifiPhyHelper wifiPhy =  YansWifiPhyHelper::Default ();
  wifiPhy.Set ("RxGain", DoubleValue (1)); 
  //wifiPhy.Set ("ShortPlcpPreambleSupported", BooleanValue(true) ); 
  wifiPhy.Set ("TxPowerEnd", DoubleValue  (16) );
  wifiPhy.Set ("TxPowerStart", DoubleValue(16) ); 
  wifiPhy.Set ("TxPowerLevels", UintegerValue(1) ); 
  wifiPhy.Set ("TxGain", DoubleValue(1));
  wifiPhy.Set ("Frequency", UintegerValue(5180));
  wifiPhy.Set ("ChannelWidth", UintegerValue(20));
  wifiPhy.Set ("EnergyDetectionThreshold",DoubleValue(-96));
  wifiPhy.Set ("RxNoiseFigure", DoubleValue(7));
  wifiPhy.Set ("TxAntennas", UintegerValue(1));
  wifiPhy.Set ("RxAntennas", UintegerValue(5));
  wifiPhy.Set ("ShortGuardEnabled", BooleanValue(true));
  
  wifiPhy.SetPcapDataLinkType (YansWifiPhyHelper::DLT_IEEE802_11_RADIO); 
  /**
   * Set the data link type of PCAP traces to be used. This function has to be
   * called before EnablePcap(), so that the header of the pcap file can be
   * written correctly.
   */
  //to set the propagation models, if used. If not, just comment them 
  YansWifiChannelHelper wifiChannel;
  wifiChannel.SetPropagationDelay ("ns3::ConstantSpeedPropagationDelayModel");//,
  //wifiChannel.AddPropagationLoss ("ns3::FriisPropagationLossModel","MinLoss",DoubleValue (5), "Frequency", DoubleValue(5.0e+09));
  //wifiChannel.AddPropagationLoss ("ns3::FixedRssLossModel","Rss",DoubleValue (-20));
  wifiChannel.AddPropagationLoss ("ns3::FriisPropagationLossModel","MinLoss",DoubleValue (5),
                                     "Frequency", DoubleValue(5.18e+09));
  wifiChannel.AddPropagationLoss ("ns3::NakagamiPropagationLossModel");
  wifiPhy.SetErrorRateModel("ns3::NistErrorRateModel");
  wifiPhy.SetChannel (wifiChannel.Create ());

  WifiMacHelper wifiMac;
  wifi.SetRemoteStationManager ("ns3::ConstantRateWifiManager", //use constant rates for transmissions 
                                "DataMode",StringValue (phyMode), // The transmission mode to use for every data packet transmission 
                                "ControlMode",StringValue (phyMode)); // The transmission mode to use for every ATIM/ATIMACK packet transmission

  wifiMac.SetType ("ns3::AdhocWifiMac");
  NetDeviceContainer devices = wifi.Install (wifiPhy, wifiMac, c);
  
 
 //aggregate IP/TCP/UDP functionality to existing Nodes. 
  InternetStackHelper internet;
  internet.Install (c);

  Ipv4AddressHelper ipv4;
  NS_LOG_INFO ("Assign IP Addresses.");
  ipv4.SetBase ("10.1.1.0", "255.255.255.0");
  Ipv4InterfaceContainer i = ipv4.Assign (devices); 

  /*int16_t port = 4000;
  UdpServerHelper server (port);
  ApplicationContainer serverapp = server.Install (c);
  serverapp.Start (Seconds (1.0));
  serverapp.Stop (Seconds (1.04));
  
  UdpClientHelper client (i.GetAddress (0), port); //primeiro nó
  client.SetAttribute ("MaxPackets", UintegerValue (1));
  client.SetAttribute ("Interval", TimeValue (Seconds (0.00000001)));
  client.SetAttribute ("PacketSize", UintegerValue (100));

  ApplicationContainer clientapp = client.Install (c.Get(2));//envia do terceiro pro primeiro
  clientapp.Start (Seconds (1.0));
  clientapp.Stop (Seconds (1.04));

  client.SetAttribute("RemoteAddress", AddressValue(i.GetAddress (3))); //envia do terceiro pro quarto
  clientapp = client.Install (c.Get(2));
  clientapp.Start (Seconds (1.01));
  clientapp.Stop (Seconds (1.04));

  client.SetAttribute("RemoteAddress", AddressValue(i.GetAddress (3))); //envia do segundo pro terceiro
  clientapp = client.Install (c.Get(1));
  clientapp.Start (Seconds (1.01));
  clientapp.Stop (Seconds (1.04));

  client.SetAttribute("RemoteAddress", AddressValue(i.GetAddress (3)));  //envia do quinto pro quarto
  clientapp = client.Install (c.Get(4));
  clientapp.Start (Seconds (1.0103));
  clientapp.Stop (Seconds (1.04));*/

  uint16_t port = 4000;
  uint32_t MaxPacketSize = 100;
  uint32_t maxPacketCount = 1;
  UdpServerHelper server (port);
  ApplicationContainer apps = server.Install (c);
  apps.Start (Seconds (1.0));
  apps.Stop (Seconds (1.04));  //the ATIM window duration
  
  UdpClientHelper client (i.GetAddress (0), port);
  client.SetAttribute ("MaxPackets", UintegerValue (maxPacketCount));
  client.SetAttribute ("Interval", TimeValue (interPacketInterval));
  client.SetAttribute ("PacketSize", UintegerValue (MaxPacketSize));
  //as the network is considered saturated, every node tries to send ATIM to the others
  for (uint16_t serverNode = 0; serverNode < nStas; serverNode++) {
      client.SetAttribute("RemoteAddress", AddressValue(i.GetAddress (serverNode))); 
        for (uint16_t clientNode = 0; clientNode < nStas; clientNode++) {     
            if (clientNode == serverNode)
            {
                continue;
            }
            //Backoff in the beginning to try to decrease the packet collision
            double min = 0;
            double max = 4; 
            Ptr<UniformRandomVariable> y = CreateObject<UniformRandomVariable> ();
            y->SetAttribute ("Min", DoubleValue (min));
            y->SetAttribute ("Max", DoubleValue (max));
            double initbackoff = 1+ floor(y->GetValue())*timeSlot;
            NS_LOG_UNCOND(" backoff = " << initbackoff << " client = " << clientNode << " to servidor = " << serverNode);
            apps = client.Install (c.Get (clientNode));
            apps.Start (Seconds (initbackoff));
            apps.Stop (Seconds (1.04));
        }
   }  
  Config::Connect ("/NodeList/*/DeviceList/0/Phy/PhyTxBegin", MakeCallback (&PhyTxBegin));
  //Config::Connect ("/NodeList/*/DeviceList/0/Phy/PhyRxEnd", MakeCallback (&PhyRxEnd));PhyTxDrop
  Config::Connect ("/NodeList/*/DeviceList/0/Phy/PhyTxDrop", MakeCallback (&PhyTxDrop));

  Config::Connect ("/NodeList/*/DeviceList/0/$ns3::WifiNetDevice/Mac/MacTx" , MakeCallback (&MacTx));
  Config::Connect ("/NodeList/*/DeviceList/0/RemoteStationManager/MacTxAtimFailed", MakeCallback (&AtimFailed));
  Config::Connect ("/NodeList/*/DeviceList/0/$ns3::WifiNetDevice/Mac/MacTxDrop" , MakeCallback (&MacTxDrop));
  ArpCache a;
  a.PopulateArpCache (); //populate the arpcache so that we do not consider these packets overhead
//  wifiPhy.EnablePcap ("atimretry-v1", devices);
  Simulator::Stop (Seconds (1.04));
  Simulator::Run ();   
  Simulator::Destroy ();
  return 0;
}
